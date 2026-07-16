# NAME

Mojolicious::Plugin::Fondation::Auth - Fondation authentication plugin — DBIx-backed login/logout

# VERSION

version 0.02

# SYNOPSIS

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

# DESCRIPTION

[Mojolicious::Plugin::Fondation::Auth](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth) provides login and logout routes
backed by a [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) schema. It loads
[Mojolicious::Plugin::Authentication](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication) and wires it to the user model
declared by [Mojolicious::Plugin::Fondation::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AUser).

Password hashing (Argon2id) is handled by the Result class
([Mojolicious::Plugin::Fondation::Auth::Schema::Result::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth%3A%3ASchema%3A%3AResult%3A%3AUser)) via
`insert`/`update` hooks — the plugin only verifies.

# DEPENDENCIES

This plugin depends on [Mojolicious::Plugin::Fondation::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AUser), which
in turn depends on [Mojolicious::Plugin::Fondation::Model::DBIx::Async](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync).
All dependency resolution is handled automatically by the Fondation plugin
loader.

# CONFIGURATION

All keys are optional and can be overridden in `myapp.conf`:

- model

    Model name used for authentication (default: `user`). Must match a model
    declared by [Mojolicious::Plugin::Fondation::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AUser) or another plugin.

        { 'Fondation::Auth' => { model => 'admin' } }

- provider

    Provider class for authentication (default:
    `Mojolicious::Plugin::Fondation::Auth::Provider::DBIx`).
    Must implement `validate_user`, `load_user`, and `auth_form`.

        { 'Fondation::Auth' => { provider => 'MyApp::Auth::Provider::LDAP' } }

- username\_column

    Column name for user login (default: `username`).

- password\_column

    Column name for the Argon2id password hash (default: `password`).

- timeout\_sessions

    Session expiration in seconds (default: `1800`, 30 minutes).

- session\_key

    Session key name used by [Mojolicious::Plugin::Authentication](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication)
    (default: `fondation`).

# ROUTES

- GET /login

    Renders the login form (`share/templates/login.html.ep`).

- POST /login

    Authenticates the user with the configured model. On success, redirects
    to `/`. On failure, redirects back to `/login` with a flash message.

- GET /logout

    Logs out the current user and redirects to `/`.

# HELPERS

- auth\_form

    Renders the login form HTML, provided by the authentication provider.

The following helpers are provided by [Mojolicious::Plugin::Authentication](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication)
and are available when this plugin is loaded:

- is\_user\_authenticated

    Returns true if the current session has an authenticated user.

        % if (is_user_authenticated) {
            <a href="/logout"><%= l 'Logout' %></a>
        % }

- current\_user

    Returns a hashref of the authenticated user's data (`uid`, `username`,
    `provider`, and all columns except password), or `undef` if not logged in.

        <p>Bonjour <%= current_user->{username} %></p>

- authenticate

    Validates credentials and logs the user in. Used by the `POST /login` route.

        if ($c->authenticate($username, $password)) { ... }

- logout

    Logs out the current user. Used by the `GET /logout` route.

        $c->logout;

# TEMPLATES

The plugin ships a login template in `share/templates/login.html.ep`.
It uses the `auth_form` helper to render the provider-specific form
and can be overridden by the application.

# TRANSLATIONS

Translation files are provided for English and French in
`share/translations/`. The following keys are used:

    Login, Logout, Username, Password, Sign in,
    Logged in as, Login failed, Logged out

# PROVIDER

Authentication is delegated to
[Mojolicious::Plugin::Fondation::Auth::Provider::DBIx](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth%3A%3AProvider%3A%3ADBIx), which builds
a synchronous [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) from the backend configuration
provided by [Mojolicious::Plugin::Fondation::Model::DBIx::Async](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync).

The provider abstraction allows future providers (LDAP, OAuth, etc.)
to be plugged in without changing the plugin itself.

# SCHEMA

The user table must include at least:

    id         TEXT PRIMARY KEY
    username   TEXT NOT NULL UNIQUE
    password   TEXT NOT NULL

Optional columns: `active`, `email`, `created_at`, `updated_at`.

The Result class [Mojolicious::Plugin::Fondation::Auth::Schema::Result::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth%3A%3ASchema%3A%3AResult%3A%3AUser)
handles Argon2id password hashing in `insert()` and `update()`.

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),
[Mojolicious::Plugin::Fondation::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AUser),
[Mojolicious::Plugin::Fondation::Model::DBIx::Async](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync),
[Mojolicious::Plugin::Authentication](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AAuthentication),
[Mojolicious::Plugin::Fondation::Auth::Schema::Result::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth%3A%3ASchema%3A%3AResult%3A%3AUser),
[Mojolicious::Plugin::Fondation::Auth::Provider::DBIx](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth%3A%3AProvider%3A%3ADBIx)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
