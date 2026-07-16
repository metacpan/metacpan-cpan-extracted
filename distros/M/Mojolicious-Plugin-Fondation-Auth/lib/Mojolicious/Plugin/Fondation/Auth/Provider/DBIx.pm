package Mojolicious::Plugin::Fondation::Auth::Provider::DBIx;
$Mojolicious::Plugin::Fondation::Auth::Provider::DBIx::VERSION = '0.02';
# ABSTRACT: DBIx::Class-backed authentication provider for Fondation::Auth

use Mojo::Base 'Mojolicious::Plugin::Fondation::Auth::Provider', -signatures;

has 'model';              # model name (e.g. 'user')
has 'username_column';    # default: 'username'
has 'password_column';    # default: 'password'

# ── Constructor ───────────────────────────────────────────────────────

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);

    $self->username_column('username') unless $self->username_column;
    $self->password_column('password') unless $self->password_column;
    $self->name('dbix');

    $self->log->debug(
        $self->model
            ? "DBIx provider initialized for model '$self->{model}'"
            : "DBIx provider initialized (model will be resolved from model_list)"
    );

    return $self;
}

# ── Authentication ────────────────────────────────────────────────────

sub validate_user ($self, $c, $username, $password, $extra = {}) {
    return undef unless $username && $password;

    my $schema = $self->_schema($c);
    return undef unless $schema;

    my $source = $self->_source($c);
    return undef unless $source;

    my $user = $schema->resultset($source)->search({
        $self->username_column => $username,
    })->single;

    return undef unless $user;

    if ($user->check_password($password)) {
        $self->log->debug("Authentication successful for '$username'");
        return $user->id // $username;
    }

    $self->log->info("Authentication failed for '$username' (invalid password)");
    return undef;
}

# ── Load user ─────────────────────────────────────────────────────────

sub load_user ($self, $app, $uid) {
    #$self->log->debug("load_user called for uid='$uid'");

    # The Authentication plugin calls load_user with the controller as
    # first argument, not the Mojolicious app. Use it directly.
    my $c      = ref($app) ? $app : $app->build_controller;
    my $schema = $self->_schema($c);
    return undef unless $schema;

    my $source = $self->_source($c);
    return undef unless $source;

    my $user = $schema->resultset($source)->find($uid);
    return undef unless $user;

    my $result = {
        uid      => $user->id // $uid,
        username => $user->get_column($self->username_column) // $uid,
        provider => 'dbix',
    };

    # Copy all user fields except the password column
    my $pass_col = $self->password_column;
    for my $col ($user->result_source->columns) {
        next if $col eq $pass_col;
        $result->{$col} = $user->get_column($col);
    }

    return $result;
}

# ── Login form ────────────────────────────────────────────────────────

sub auth_form ($self, $c) {
    my $template_file = $c->app->home->child('templates/auth/login.html.ep');
    if (-e $template_file) {
        my $mt      = Mojo::Template->new;
        my $content = $template_file->slurp;
        return $mt->render($content, $c);
    }

    return $c->render_to_string(inline => <<'HTML');
<h1><%= l 'Login' %></h1>
<form method="post">
  <%= csrf_field %>
  <label><%= l 'Username' %>:</label>
  <input type="text" name="username" required><br>
  <label><%= l 'Password' %>:</label>
  <input type="password" name="password" required><br>
  <button type="submit"><%= l 'Sign in' %></button>
</form>
HTML
}

# ── Internal ──────────────────────────────────────────────────────────

sub _schema ($self, $c) {
    return $self->{_schema} if $self->{_schema};

    my $be = $c->backend_config;
    return undef unless $be;

    my $schema_class = $be->{schema_class};
    return undef unless $schema_class;

    $self->{_schema} = $schema_class->connect(
        $be->{dsn}, $be->{user}, $be->{pass}, $be->{dbi_attrs},
    );

    $self->log->debug(
        sprintf("DBIx provider connected to %s via %s", $be->{dsn}, $schema_class));

    return $self->{_schema};
}

sub _source ($self, $c) {
    my $model_cfg = $c->model_config($self->model);
    return undef unless $model_cfg;
    return $model_cfg->{source};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Auth::Provider::DBIx - DBIx::Class-backed authentication provider for Fondation::Auth

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    $app->plugin('Fondation::Auth' => {
        model           => 'user',
        username_column => 'username',    # optional, default: 'username'
        password_column => 'password',    # optional, default: 'password'
    });

=head1 DESCRIPTION

This provider authenticates users against a L<DBIx::Class> schema, using
L<Mojolicious::Plugin::Fondation::Model::DBIx::Async> for backend configuration
discovery.

Authentication operations (C<validate_user>, C<load_user>) use a synchronous
L<DBIx::Class::Schema> instance built from the same backend config. This is
necessary because L<Mojolicious::Plugin::Authentication> requires synchronous
callbacks.

Password hashing (Argon2id) is handled by the Result class
(L<Mojolicious::Plugin::Fondation::Auth::Schema::Result::User>) via
C<insert>/C<update> hooks — the provider only verifies.

=head1 NAME

Mojolicious::Plugin::Fondation::Auth::Provider::DBIx - DBIx::Class-backed authentication provider

=head1 CONFIGURATION

=over 4

=item model

Model name as configured in C<Fondation::Model::DBIx::Async> (required).
Used to discover the table C<source> via C<model_config()>.

=item username_column

Column name for usernames (default: C<username>).

=item password_column

Column name for Argon2id password hashes (default: C<password>).

=back

=head1 REQUIREMENTS

The application must load C<Fondation::Model::DBIx::Async> before
C<Fondation::Auth>. This is handled automatically via C<fondation_meta>
dependencies when using the Fondation plugin loader.

The schema class must include the C<users> Result source (typically via
C<load_namespaces> and C<Mojolicious::Plugin::Fondation::Auth::Schema::Result::User>).

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::Auth>,
L<Mojolicious::Plugin::Fondation::Model::DBIx::Async>,
L<DBIx::Class::Schema>,
L<Mojolicious::Plugin::Fondation::Auth::Schema::Result::User>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
