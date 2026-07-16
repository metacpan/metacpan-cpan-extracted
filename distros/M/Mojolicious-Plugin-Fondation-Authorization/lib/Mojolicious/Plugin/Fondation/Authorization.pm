package Mojolicious::Plugin::Fondation::Authorization;
$Mojolicious::Plugin::Fondation::Authorization::VERSION = '0.01';
# ABSTRACT: Authorization plugin — grants loading and check_perm/check_group helpers

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [
            'Fondation::Auth',
            'Fondation::Group',
            'Fondation::Perm',
            'Fondation::SessionStore'
        ],
        defaults => {},
    };
}

sub register ($self, $app, $config) {

    # ── Helpers ──────────────────────────────────────────────────────

    $app->helper(check_perm => sub ($c, $perm) {
        return 0 unless $c->is_user_authenticated;
        my $grants = $c->session('grants');
        return 0 unless $grants && $grants->{permissions};
        return 1 if grep { $_ eq $perm } @{$grants->{permissions}};
        return 0;
    });

    $app->helper(check_group => sub ($c, $group) {
        return 0 unless $c->is_user_authenticated;
        my $grants = $c->session('grants');
        return 0 unless $grants && $grants->{groups};
        return 1 if grep { $_ eq $group } @{$grants->{groups}};
        return 0;
    });

    # ── around_dispatch — async grant loading ─────────────────────

    $app->hook(around_dispatch => sub ($next, $c) {
        unless ($c->is_user_authenticated) {
            $c->session(grants => undef);
            return $next->();
        }
        return $next->() if $c->session('grants');

        $self->_load_grants_async($c)->then(sub {
            $next->();
        })->on_fail(sub {
            my $err = shift;
            $c->app->log->error("[Authorization] Failed to load grants: $err");
            $next->();
        })->retain;
    });

    return $self;
}

# ── Internal: async loading via $c->model ──────────────────────────

sub _load_grants_async ($self, $c) {
    my $uid = $c->current_user->{uid};
    my $log = $c->app->log;

    $log->info("[Authorization] Loading grants for uid=$uid");

    # Load groups — user → user_group → group
    my $groups_f = $c->model('group')->search(
        { 'user_group.user_id' => $uid },
        { join => 'user_group' },
    )->all->then(sub {
        my $rows = shift;
        $log->info("[Authorization] Groups query returned " . scalar(@$rows) . " rows");
        return [map { $_->name } @$rows];
    });

    # Load permissions — user → user_group → group → group_perm → perm
    my $perms_f = $c->model('perm')->search(
        { 'user_group.user_id' => $uid },
        {
            join     => { group_perm => { group => { user_group => undef } } },
            distinct => 1,
        },
    )->all->then(sub {
        my $rows = shift;
        $log->info("[Authorization] Perms query returned " . scalar(@$rows) . " rows");
        return [map { $_->name } @$rows];
    });

    # Combine both results and store in session
    return Future->needs_all($groups_f, $perms_f)->then(sub {
        my ($groups, $perms) = @_;

        $log->info(sprintf '[Authorization] Loaded %d groups, %d perms for uid=%s',
            scalar @$groups, scalar @$perms, $uid);

        $c->session(grants => {
            permissions => $perms,
            groups      => $groups,
        });
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Authorization - Authorization plugin — grants loading and check_perm/check_group helpers

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Authorization',
        ],
    };

=head1 DESCRIPTION

Loads user grants (permissions and groups) from the database and provides
C<check_perm> and C<check_group> helpers for synchronous access control.

Grants are fetched asynchronously via C<$c->model> once per session on
first request via an C<around_dispatch> hook and cached in
C<< $c->session('grants') >>.

Subsequent requests use the cached values — no database queries.

Request flow:

  is_user_authenticated?
    NO  → session(grants => undef) + continue  (cleanup)
    YES → grants in session?
             YES → continue  (fast path)
             NO  → load grants async + continue

The grant chain is:

  user → user_group → group → group_perm → perm

There is no direct user-to-permission table. All permissions are inherited
through group membership.

=head1 NAME

Mojolicious::Plugin::Fondation::Authorization - Permission and group authorization for Fondation

=head1 DEPENDENCIES

=over 4

=item L<Mojolicious::Plugin::Fondation::Auth>

Provides C<is_user_authenticated> and C<current_user> helpers.

=item L<Mojolicious::Plugin::Fondation::Group>

Provides C<user_group> and C<group> DBIx sources + models.

=item L<Mojolicious::Plugin::Fondation::Perm>

Provides C<group_perm> and C<perm> DBIx sources + models.

=back

=head1 HELPERS

=head2 check_perm

    if ($c->check_perm('user_create')) { ... }

=head2 check_group

    if ($c->check_group('admins')) { ... }

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
