package Mojolicious::Plugin::ContextAuth;

# ABSTRACT: Role-based access with context

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Carp;
use Mojolicious::Plugin::ContextAuth::Auth;
use Mojolicious::Plugin::ContextAuth::DB;

use feature 'postderef';
no warnings 'experimental::postderef';

our $VERSION = '0.01';

sub register ( $self, $app, $config ) {
    croak 'no config given'      if !$config;
    croak 'config not a hashref' if 'HASH' ne ref $config;

    my $prefix = $config->{prefix} // 'auth';

    $app->helper(
        $prefix => sub ($c) {
            state $auth //= Mojolicious::Plugin::ContextAuth::Auth->new(
                db => $c->auth_db,
            );

            return $auth;
        }
    );

    $app->helper(
        $prefix . '_db' => sub ($c) {
            state $db //= Mojolicious::Plugin::ContextAuth::DB->new(
                $config->%*,
            );

            return $db;
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth - Role-based access with context

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # Mojolicious::Lite app
    app->plugin(
        'ContextAuth' => {
            dsn => 'sqlite:' . $db,
        },
    );

    # Mojolicious app in sub startup
    $self->plugin(
        'ContextAuth' => {
            dsn => 'sqlite:' . $db,
        },
    );

    # in your controller
    my $has_permission = $c->auth->has_permission(
        $session_id, 
        context    => 'project_a',
        permission => 'title.update',
    )

=head1 DESCRIPTION

This addon implements a role based authorization with contexts. There are systems 
where the user can have different roles in different contexts: e.g.  in a company 
that develops software, one user can have the projectmanager role in one project, 
but not in an other project.

With this module it is easy to implement it. It creates the database and provides
some methods to do the authentication and authorization.

=head1 DATABASE

       .---------------.         .---------------------------.              .---------------------.
       | corbac_users  |         | corbac_user_context_roles |              |   corbac_contexts   |
       |---------------|         |---------------------------|              |---------------------|
       | user_id       |<--------| user_id                   |------------->| context_id          |
       | username      |         | context_id                |              | context_name        |
       | user_password |         | role_id                   |              | context_description |
       '---------------'         '---------------------------'              '---------------------'
               ^                               ^                                       ^
               |                               |                                       |
               |                               |                                       |
               |                               |                                       |
               |                               |                                       |
   .----------------------.          .------------------.                              |
   | corbac_user_sessions |          |   corbac_roles   |                              |
   |----------------------|          |------------------|                              |
   | user_id              |          | role_id          |                              |
   | session_id           |          | role_name        |------------------------------'
   | access_tree          |          | role_description |
   | session_started      |          | context_id       |
   '----------------------'          | is_valid         |
                                     '------------------'
                                               ^
                                               |
                                  .-------------------------.
                                  | corbac_role_permissions |
                                  |-------------------------|
                  .---------------| role_id                 |------------.
                  |               | permission_id           |            |
                  |               | resource_id             |            |
                  |               '-------------------------'            |
                  |                                                      |
                  v                                                      v
     .------------------------.                              .----------------------.
     |   corbac_permissions   |                              |   corbac_resources   |
     |------------------------|                              |----------------------|
     | permission_id          |                              | resource_id          |
     | permission_name        |----------------------------->| resource_name        |
     | permission_label       |                              | resource_label       |
     | permission_description |                              | resource_description |
     | resource_id            |                              '----------------------'
     '------------------------'

Currently only SQLite is supported.

=head1 ENTITIES

We use some entities that are described in the subsequent paragraphs. But one example
might describe it as well:

  Mr Johnson can update the project description in project A as he is the project manager
   ^            ^               ^                     ^                     ^
   |            |               |                     |                     |
  user        permission     resource              context                 role

=head2 User

The user of the system

=head2 Context

The context the user does an action. In a project management software this could
be "system", "project a", "project b". You can define any context you want.

=head2 Role

The role an user has in the given context. A user can be the project manager in one
project, but a developer in an other project.

=head2 Resource

This is any resource you have in your system. This could be "title" and "members"
for a project.

=head2 Permission

Any permission is bind to a resource. You can define whatever permissions
you want. For the project name this could be "update", for the project members
it coule be "add", "delete", "set_role".

=head1 METHODS

=head2 register

Configuration:

=over 4

=item * dsn

Required.

This is a dsn used for L<Mojo::SQLite>, L<Mojo::mysql> or L<Mojo::Pg>.

=item * prefix

Optional (default: 'auth').

Used to name the helpers (see below)

=back

=head1 HELPERS

Those helpers are defined by the plugin:

=head2 <prefix>

Returns a L<Mojolicious::Plugin::ContextAuth::Auth> object.

=head2 <prefix>_db

Returns a L<Mojolicious::Plugin::ContextAuth::DB> object.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
