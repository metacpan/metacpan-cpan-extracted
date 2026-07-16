package Mojolicious::Plugin::Fondation::Auth;
$Mojolicious::Plugin::Fondation::Auth::VERSION = '0.02';
# ABSTRACT: Fondation authentication plugin — DBIx-backed login/logout

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojolicious::Plugin::Fondation::Auth::Provider::DBIx;

sub fondation_meta {
    return {
        dependencies => ['Fondation::User', 'Fondation::Problem'],
        after        => ['Fondation::User::UI::Bootstrap'],
        defaults     => {
            model            => 'user',    # model name from Fondation::User, overridable
            provider         => 'Mojolicious::Plugin::Fondation::Auth::Provider::DBIx',
            username_column  => 'username',
            password_column  => 'password',
            timeout_sessions => 1800,
            session_key      => 'fondation',
        },
        setup => {
            label       => 'Authentication',
            description => 'DBIx-backed login/logout with session management',
            parameters  => [
                {
                    key         => 'model',
                    label       => 'Model Name',
                    type        => 'string',
                    default     => 'user',
                    placeholder => 'Model name from Fondation::User',
                },
                {
                    key         => 'provider',
                    label       => 'Auth Provider Class',
                    type        => 'string',
                    default     => 'Mojolicious::Plugin::Fondation::Auth::Provider::DBIx',
                    placeholder => 'Perl class implementing validate_user, load_user, auth_form',
                },
                {
                    key         => 'username_column',
                    label       => 'Username Column',
                    type        => 'string',
                    default     => 'username',
                },
                {
                    key         => 'password_column',
                    label       => 'Password Column',
                    type        => 'string',
                    default     => 'password',
                },
                {
                    key         => 'timeout_sessions',
                    label       => 'Session Timeout (seconds)',
                    type        => 'integer',
                    default     => 1800,
                },
                {
                    key         => 'session_key',
                    label       => 'Session Key',
                    type        => 'string',
                    default     => 'fondation',
                },
            ],
        },
    };
}

sub register ($self, $app, $config) {

    # ── Session timeout ──────────────────────────────────────────────
    if (my $timeout = $config->{timeout_sessions}) {
        $app->sessions->default_expiration($timeout);
        $self->log->debug("session timeout set to $timeout seconds");
    }

    # ── Provider ─────────────────────────────────────────────────────
    my $provider_class = $config->{provider};
    $self->log->debug("using provider $provider_class");
    my $provider = $provider_class->new(
        %$config,
        app => $app,
    );

    # ── Authentication plugin ────────────────────────────────────────
    $app->plugin('Authentication' => {
        session_key   => $config->{session_key},
        load_user     => sub ($app, $uid) {
            return $provider->load_user($app, $uid);
        },
        validate_user => sub ($c, $username, $password, $extra = {}) {
            return $provider->validate_user($c, $username, $password, $extra);
        },
    });

    # ── Helpers ──────────────────────────────────────────────────────
    $app->helper(auth_form => sub ($c) {
        return $provider->auth_form($c);
    });

    # ── Routes ───────────────────────────────────────────────────────
    my $r = $app->routes;

    # ── Route condition: fondation.authenticated ────────────────────
    # Overrides the no-op fallback registered by Fondation core.
    $app->routes->add_condition('fondation.authenticated' => sub {
        my ($route, $c, $captures, $required) = @_;
        my $auth = $c->is_user_authenticated;
        my $pass = $required ? $auth : !$auth;
        return 1 if $pass;
        $c->problem(status => 403, title => 'Forbidden');
        return undef;
    });

    $r->get('/login')
        ->requires('fondation.authenticated' => 0)
        ->to(cb => sub {
        my $c = shift;
        $c->render('login');
    });

    $r->post('/login')
        ->requires('fondation.authenticated' => 0)
        ->to(cb => sub {
        my $c       = shift;
        my $username = $c->param('username');
        my $password = $c->param('password');

        if ($c->authenticate($username, $password)) {
            my $user     = $c->current_user;
            my $username = $user->{username};
            $c->flash(message => $c->l('Logged in as') . " $username", message_class => 'alert-success');
            $c->redirect_to('/');
        }
        else {
            $c->flash(message => $c->l('Login failed'), message_class => 'alert-danger');
            $c->redirect_to('/login');
        }
    });

    $r->get('/logout')
        ->requires('fondation.authenticated' => 1)
        ->to(cb => sub {
        my $c = shift;
        $c->logout;
        $c->flash(message => $c->l('Logged out'), message_class => 'alert-success');
        $c->redirect_to('/');
    });

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Auth - Fondation authentication plugin — DBIx-backed login/logout

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Model::DBIx::Async',
            'Fondation::User',
            'Fondation::Auth',
        ],
    };

    # Override the provider (e.g. for LDAP):
    plugin 'Fondation' => {
        dependencies => [
            { 'Fondation::Auth' => {
                provider => 'MyApp::Auth::Provider::LDAP',
            }},
        ],
    };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Fondation::Auth> provides login and logout routes
backed by a L<DBIx::Class> schema. It loads
L<Mojolicious::Plugin::Authentication> and wires it to the user model
declared by L<Mojolicious::Plugin::Fondation::User>.

Password hashing (Argon2id) is handled by the Result class
(L<Mojolicious::Plugin::Fondation::Auth::Schema::Result::User>) via
C<insert>/C<update> hooks — the plugin only verifies.

=head1 DEPENDENCIES

This plugin depends on L<Mojolicious::Plugin::Fondation::User>, which
in turn depends on L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>.
All dependency resolution is handled automatically by the Fondation plugin
loader.

=head1 CONFIGURATION

All keys are optional and can be overridden in C<myapp.conf>:

=over 4

=item model

Model name used for authentication (default: C<user>). Must match a model
declared by L<Mojolicious::Plugin::Fondation::User> or another plugin.

    { 'Fondation::Auth' => { model => 'admin' } }

=item provider

Provider class for authentication (default:
C<Mojolicious::Plugin::Fondation::Auth::Provider::DBIx>).
Must implement C<validate_user>, C<load_user>, and C<auth_form>.

    { 'Fondation::Auth' => { provider => 'MyApp::Auth::Provider::LDAP' } }

=item username_column

Column name for user login (default: C<username>).

=item password_column

Column name for the Argon2id password hash (default: C<password>).

=item timeout_sessions

Session expiration in seconds (default: C<1800>, 30 minutes).

=item session_key

Session key name used by L<Mojolicious::Plugin::Authentication>
(default: C<fondation>).

=back

=head1 ROUTES

=over 4

=item GET /login

Renders the login form (C<share/templates/login.html.ep>).

=item POST /login

Authenticates the user with the configured model. On success, redirects
to C</>. On failure, redirects back to C</login> with a flash message.

=item GET /logout

Logs out the current user and redirects to C</>.

=back

=head1 HELPERS

=over 4

=item auth_form

Renders the login form HTML, provided by the authentication provider.

=back

The following helpers are provided by L<Mojolicious::Plugin::Authentication>
and are available when this plugin is loaded:

=over 4

=item is_user_authenticated

Returns true if the current session has an authenticated user.

    % if (is_user_authenticated) {
        <a href="/logout"><%= l 'Logout' %></a>
    % }

=item current_user

Returns a hashref of the authenticated user's data (C<uid>, C<username>,
C<provider>, and all columns except password), or C<undef> if not logged in.

    <p>Bonjour <%= current_user->{username} %></p>

=item authenticate

Validates credentials and logs the user in. Used by the C<POST /login> route.

    if ($c->authenticate($username, $password)) { ... }

=item logout

Logs out the current user. Used by the C<GET /logout> route.

    $c->logout;

=back

=head1 TEMPLATES

The plugin ships a login template in C<share/templates/login.html.ep>.
It uses the C<auth_form> helper to render the provider-specific form
and can be overridden by the application.

=head1 TRANSLATIONS

Translation files are provided for English and French in
C<share/translations/>. The following keys are used:

    Login, Logout, Username, Password, Sign in,
    Logged in as, Login failed, Logged out

=head1 PROVIDER

Authentication is delegated to
L<Mojolicious::Plugin::Fondation::Auth::Provider::DBIx>, which builds
a synchronous L<DBIx::Class::Schema> from the backend configuration
provided by L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>.

The provider abstraction allows future providers (LDAP, OAuth, etc.)
to be plugged in without changing the plugin itself.

=head1 SCHEMA

The user table must include at least:

    id         TEXT PRIMARY KEY
    username   TEXT NOT NULL UNIQUE
    password   TEXT NOT NULL

Optional columns: C<active>, C<email>, C<created_at>, C<updated_at>.

The Result class L<Mojolicious::Plugin::Fondation::Auth::Schema::Result::User>
handles Argon2id password hashing in C<insert()> and C<update()>.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,
L<Mojolicious::Plugin::Fondation::User>,
L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>,
L<Mojolicious::Plugin::Authentication>,
L<Mojolicious::Plugin::Fondation::Auth::Schema::Result::User>,
L<Mojolicious::Plugin::Fondation::Auth::Provider::DBIx>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
