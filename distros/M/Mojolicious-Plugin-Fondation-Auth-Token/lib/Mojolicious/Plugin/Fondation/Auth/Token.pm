package Mojolicious::Plugin::Fondation::Auth::Token;
$Mojolicious::Plugin::Fondation::Auth::Token::VERSION = '0.01';
# ABSTRACT: Personal Access Token authentication for Fondation

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Digest::SHA qw(sha256_hex);
use Crypt::URandom qw(urandom);
use Future;

sub fondation_meta {
    return {
        dependencies => [
            'Fondation::Model::DBIx::Async',
            'Fondation::Auth',
            'Fondation::Problem',
        ],
        defaults => {
            models => {
                api_token => {
                    source  => 'ApiToken',
                    backend => undef,
                },
            },
        },
    };
}

sub register ($self, $app, $config) {

    # ── around_dispatch: validate Bearer, set current_user, flag stash ──

    $app->hook(around_dispatch => sub ($next, $c) {
        my $token = _extract_bearer($c) or return $next->();

        my $hash = sha256_hex($token);

        $c->model('api_token')->search(
            { token_hash => $hash },
            { rows => 1 },
        )->first->then(sub ($api_token) {
            unless ($api_token) {
                $c->stash('fondation.bearer_invalid' => 1);
                return $next->();
            }

            my $user_id = $api_token->user_id;

            return $c->model('user')->find($user_id)->then(sub ($user) {
                unless ($user) {
                    $app->log->error(
                        "[Auth::Token] User $user_id not found for valid token");
                    $c->stash('fondation.bearer_invalid' => 1);
                    return $next->();
                }
                $c->current_user({ $user->get_columns });
                $c->stash('fondation._bearer_auth' => 1);

                return $api_token->update(
                    { last_used_at => \'datetime(\'now\')' }
                )->then(sub {
                    _load_grants($c);
                })->then(sub { $next->() });
            });
        })->on_fail(sub ($err) {
            $app->log->error("[Auth::Token] Token lookup failed: $err");
            $c->stash('fondation.bearer_invalid' => 1);
            $next->();
        })->retain;
    });

    # ── around_action: enforce Bearer opt-in ──────────────────────────
    # ── Route is matched, check endpoint requires ────────────────────

    $app->hook(around_action => sub ($next, $c, $action, $captures) {
        return $next->() unless $c->stash('fondation._bearer_auth');

        my $endpoint = $c->match->endpoint;
        my $allows   = 0;
        if ($endpoint) {
            my $requires = $endpoint->{requires} // [];
            my %conds;
            for (my $i = 0; $i < @$requires; $i += 2) {
                $conds{$requires->[$i]} = $requires->[$i+1] // 1;
            }
            $allows = 1 if $conds{'fondation.bearer'};
        }

        unless ($allows) {
            delete $c->stash->{'current_user'};
            $c->problem(
                status => 403,
                title  => 'Access denied',
                detail => 'Bearer token not allowed on this route',
            );
            return;
        }

        return $next->();
    });

    # ── Route condition: fondation.bearer ────────────────────────────

    $app->routes->add_condition('fondation.bearer' => sub {
        my ($route, $c, $captures) = @_;

        return 1 unless $route->{requires}
            && grep { $_ eq 'fondation.bearer' } @{$route->{requires}};
        return 1 unless $route->pattern->match($c->req->url->path->to_string);

        if ($c->stash('fondation.bearer_invalid')) {
            $c->problem(
                status => 403,
                title  => 'Access denied',
                detail => 'Invalid bearer token',
            ) if !$c->res->code || $c->res->code == 200;
            return undef;
        }

        return 1 if $c->is_user_authenticated;

        $c->problem(
            status => 401,
            title  => 'Access denied',
            detail => 'Authentication required',
        ) if !$c->res->code || $c->res->code == 200;
        return undef;
    });

    # ── Token management API routes ──────────────────────────────────

    $app->routes->get('/api/ApiToken')
        ->to('ApiToken#list');

    $app->routes->delete('/api/ApiToken/:id')
        ->to('ApiToken#remove');

    $app->routes->post('/api/token/generate')
        ->to('ApiToken#generate');

    return $self;
}

# ── Extract Bearer token from Authorization header ────────────────────

sub _extract_bearer ($c) {
    my $header = $c->req->headers->authorization or return;
    return unless $header =~ /^Bearer\s+(.+)$/i;
    return $1;
}

# ── Load grants (permissions + groups) into session ───────────────────

sub _load_grants ($c) {
    my $reg = $c->fondation->registry;

    return Future->done
        unless $reg->{'Mojolicious::Plugin::Fondation::Authorization'}
        && $reg->{'Mojolicious::Plugin::Fondation::Group'}
        && $reg->{'Mojolicious::Plugin::Fondation::Perm'};

    my $uid = $c->current_user->{id};

    my $groups_f = $c->model('group')->search(
        { 'user_group.user_id' => $uid },
        { join => 'user_group' },
    )->all->then(sub {
        my $rows = shift;
        return [ map { $_->name } @$rows ];
    });

    my $perms_f = $c->model('perm')->search(
        { 'user_group.user_id' => $uid },
        { join    => { group_perm => { group => { user_group => undef } } },
          distinct => 1 },
    )->all->then(sub {
        my $rows = shift;
        return [ map { $_->name } @$rows ];
    });

    return Future->needs_all($groups_f, $perms_f)->then(sub {
        my ($groups, $perms) = @_;
        $c->session(grants => { permissions => $perms, groups => $groups });
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Auth::Token - Personal Access Token authentication for Fondation

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Model::DBIx::Async',
            'Fondation::Auth',
            'Fondation::Auth::Token',
        ],
    };

    # Opt-in on API routes — combine with other conditions:
    $r->get('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_read')
      ->to('User#list');

    # Routes without fondation.bearer reject Bearer headers with 403.

=head1 DESCRIPTION

This plugin adds Bearer token authentication to a Fondation application.
It provides the C<fondation.bearer> route condition which must be
explicitly added to routes that should accept Bearer tokens.

A token is a random string whose SHA-256 hash is stored in the C<api_tokens>
table. Tokens are created via CLI or fixtures — there is no HTTP endpoint
for token creation (no login/password in scripts).

=head1 NAME

Mojolicious::Plugin::Fondation::Auth::Token - Personal Access Token for Fondation

=head1 EXAMPLE — Protecting an API route

    $r->get('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_read')
      ->to('User#list');

The order of C<requires> does not matter — Mojo evaluates all conditions.

=head2 With C<fondation.bearer> only (no Authorization plugin)

    $r->get('/api/data')
      ->requires('fondation.bearer')
      ->to(cb => sub ($c) { $c->render(json => { ok => true }) });

Any authenticated request (Bearer or cookie) is accepted. Invalid Bearer
tokens return 403. Unauthenticated requests return 401.

=head2 With C<fondation.bearer> + C<fondation.perm>

    $r->get('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_read')
      ->to('User#list');

The request must be authenticated AND the user must hold the C<user_read>
permission. Both conditions are checked independently.

=head1 ROUTE CONDITION

=head2 fondation.bearer

Opt-in condition. Add C<< ->requires('fondation.bearer') >> to any route
that should accept Bearer token authentication.

    $r->get('/api/data')
      ->requires('fondation.bearer')
      ->to('Data#list');

Behaviours:

    Authorization header        Token       Result
    ──────────────────────      ──────      ──────
    Bearer <valid>              valid       200 (user authenticated)
    (none, cookie session)      ignored     200 (if session valid)
    Bearer <invalid>            invalid     403 "Invalid bearer token"
    (none, no cookie)           ignored     401 "Authentication required"

Routes B<without> C<fondation.bearer> reject any Bearer header with 403.
In production mode the message is C<"Access denied">; in development mode
it includes C<"Bearer token not allowed on this route"> for debugging.

The condition is compatible with C<fondation.perm>, C<fondation.group>,
and C<fondation.authenticated>. Stack them as needed:

    $r->post('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_create')
      ->to('User#create');

=head1 DEPENDENCIES

=over 4

=item L<Mojolicious::Plugin::Fondation::Auth>

=item L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>

=back

=head1 TABLE

    CREATE TABLE api_tokens (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL REFERENCES users(id),
        token_hash   TEXT NOT NULL UNIQUE,
        name         VARCHAR(255) NOT NULL,
        scopes       TEXT,
        last_used_at DATETIME,
        created_at   DATETIME NOT NULL
    );

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,
L<Mojolicious::Plugin::Fondation::Auth>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
