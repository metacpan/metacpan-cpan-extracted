package Mojolicious::Plugin::ContextAuth::DB;

# ABSTRACT: Main class to do the database stuff

use Mojo::Base -base, -signatures;

use Crypt::Eksblowfish::Bcrypt ();
use Crypt::URandom ();
use Mojo::Util qw(secure_compare camelize);
use Session::Token;

use Mojolicious::Plugin::ContextAuth::DB::User;
use Mojolicious::Plugin::ContextAuth::DB::Context;
use Mojolicious::Plugin::ContextAuth::DB::Permission;
use Mojolicious::Plugin::ContextAuth::DB::Role;
use Mojolicious::Plugin::ContextAuth::DB::Resource;

use Carp;

has token => sub {
    Session::Token->new;
};
has [qw/dsn error/];

has session_expires => sub { 3600 };

has dbh    => sub ($self) {
    my $dsn = $self->dsn;

    my $dbh;
    my $name;
    if ( $dsn =~ m{^SQLite}xi ) {
        require Mojo::SQLite;
        $dbh  = Mojo::SQLite->new( $dsn );
        $name = 'sqlite';

        $dbh->on(connection => sub {
            my ($sql, $sqlite_dbh) = @_;
            $sqlite_dbh->do('PRAGMA foreign_keys = ON');
        });
    }
    elsif ( $dsn =~ m{^postgres}xi ) {
        require Mojo::Pg;
        $dbh  = Mojo::Pg->new( $dsn );
        $name = 'postgres';
    }
    elsif ( $dsn =~ m{^(?:mariadb|mysql)}xi ) {
        require Mojo::mysql;
        $dbh  = Mojo::mysql->strict_mode( $dsn );
        $name = 'mysql';
    }
    else {
        croak 'invalid dsn, need dsn in Mojo::{Pg,SQLite,mysql} syntax';
    }

    $dbh->migrations->from_data( __PACKAGE__, $name );
    $dbh->auto_migrate( 1 );

    return $dbh;
};

sub login ($self, $username, $password) {
    $self->error('');

    if ( !$username || !$password ) {
        $self->error('Need username and password');
        return;
    }

    my $user = $self->dbh->db->select(
        corbac_users => [qw/user_id username user_password/],
        {
            username => $username,
        },
    );

    my $hash = $user->hash;
    if ( !$hash ) {
        $self->error( 'Wrong username or password');
        return;
    }

    my $is_equal = secure_compare(
        Crypt::Eksblowfish::Bcrypt::bcrypt(
            $password,
            $hash->{user_password},
        ),
        $hash->{user_password},
    );

    if ( !$is_equal ) {
        $self->error( 'Wrong username or password');
        return;
    }

    my $session_id = $self->token->get;

    my $user_object = $self->get('user', $hash->{user_id});
    $user_object->add_session( $session_id );

    return $session_id;
}

sub user_from_session ($self, $session_id) {
    $self->error('');

    if ( !$session_id ) {
        $self->error( "Need session id" );
        return;
    }

    my $user_id = $self->dbh->db->select(
        corbac_user_sessions => [ qw/user_id/ ],
        {
            session_id      => $session_id,
            session_started => { '>' => time - $self->session_expires },
        },
    );

    my $hash = $user_id->hash;

    if ( !$hash ) {
        $self->error('No session found');
        return;
    }

    my $user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $self->dbh );

    return $user->load(
        $hash->{user_id},
    );
}

sub add ($self, $object, %params) {
    $self->error('');

    my $class = 'Mojolicious::Plugin::ContextAuth::DB::' . camelize( lc $object );
    my $obj   = $class->new( dbh => $self->dbh );

    my $result = $obj->add( %params );
    if ( !$result ) {
        $self->error( $obj->error );
        return;
    }

    return $result;
}

sub delete ($self, $object, $id) {
    $self->error('');
    
    my $class = 'Mojolicious::Plugin::ContextAuth::DB::' . camelize( lc $object );
    my $obj   = $class->new( dbh => $self->dbh );

    my $result = $obj->delete( $id );
    if ( !$result ) {
        $self->error( $obj->error );
        return;
    }

    return $result;
}

sub update ($self, $object, $id, %params) {
    $self->error('');

    my $class = 'Mojolicious::Plugin::ContextAuth::DB::' . camelize( lc $object );
    my $obj   = $class->new( dbh => $self->dbh );

    my $found = $obj->load( $id );
    if ( !$found ) {
        $self->error( $obj->error );
        return;
    }

    my $result = $found->update( %params );
    if ( !$result ) {
        $self->error( $found->error );
        return;
    }

    return $result;
}

sub get ($self, $object, $id) {
    $self->error('');

    my $class = 'Mojolicious::Plugin::ContextAuth::DB::' . camelize( lc $object );
    my $obj   = $class->new( dbh => $self->dbh );

    return $obj->load(
        $id,
    );
}

sub search ($self, $object, %params) {
    $self->error('');

    my $class = 'Mojolicious::Plugin::ContextAuth::DB::' . camelize( lc $object );
    my $obj   = $class->new( dbh => $self->dbh );

    my @rows = $obj->search( %params );
    $self->error( $obj->error );
    
    return @rows;
}

sub object ($self, $object) {
    $self->error('');

    my $class = 'Mojolicious::Plugin::ContextAuth::DB::' . camelize( lc $object );
    my $obj   = $class->new( dbh => $self->dbh );

    return $obj;
}

sub clear_sessions ($self) {
    $self->dbh->db->delete(
        'corbac_user_sessions' => {
            session_started => { '<' => time - $self->session_expires },
    });
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth::DB - Main class to do the database stuff

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Mojolicious::Plugin::ContextAuth::DB;

    use Mojo::File qw(path);

    my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

    my $db = Mojolicious::Plugin::ContextAuth::DB->new(
        dsn => 'sqlite:' . $file,
    );

    my $session_id = $db->login( 'user', 'password' );

    # later

    my $user = $db->user_from_session( $session_id );

=head1 ATTRIBUTES

=over 4

=item * dsn

=item * error

=item * dbh

=item * token

=item * session_expires

=back

=head1 METHODS

=head2 login

    my $session_id = $db->login( 'user', 'password' );

Returns the session id if I<user> and I<password> was correct.

=head2 user_from_session

    my $user = $db->user_from_session( $session_id );

Returns a L<Mojolicious::Plugin::ContextAuth::DB::User> object, if a user exists that is tied to the session id.
It returns C<undef> if no user was found.

=head2 add

    my $user = $db->add(
        'user',
        user_id       => '1234',
        username      => 'username',
        user_password => '123',
    );

    warn $db->error if !$user;

This is a proxy for the C<add> methods of the C<Mojolicious::Plugin::ContextAuth::DB::*> modules.

=head2 get

    my $user = $db->get(
        'user' => '1234',
    );

    warn $db->error if !$user;

This is a proxy for the C<load> methods of the C<Mojolicious::Plugin::ContextAuth::DB::*> modules.

=head2 update

    my $updated_user = $db->update(
        'user'        => '1234',
        username      => 'username',
        user_password => '123',
    );

    warn $db->error if !$updated_user;

Returns the object that reflects the updated object. If the object could not be updated

This is a proxy for the C<update> methods of the C<Mojolicious::Plugin::ContextAuth::DB::*> modules.

=head2 delete

    my $success = $db->delete(
        'user' => '1234',
    );

    warn $db->error if !$success;

It returns C<1> on success, C<undef> otherwise.

This is a proxy for the C<add> methods of the C<Mojolicious::Plugin::ContextAuth::DB::*> modules.

=head2 search

=head2 clear_sessions

    $db->clear_sessions();

Removes all sessions from the C<corbac_user_sessions> table that are expired.

=head2 object

    my $obj = $db->object('user');

Returns an instance of the C<Mojolicious::Plugin::ContextAuth::DB::*>

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
@@ sqlite
-- 1 up
CREATE TABLE corbac_users ( user_id VARCHAR(45) PRIMARY KEY NOT NULL, username VARCHAR(255) NOT NULL, user_password VARCHAR(200) NOT NULL, CONSTRAINT uq_app_user UNIQUE (username) );
CREATE TABLE corbac_user_sessions ( user_id INTEGER NOT NULL, session_id VARCHAR(45) NOT NULL, session_started INTEGER NOT NULL, CONSTRAINT uq_session_id UNIQUE(session_id), FOREIGN KEY (user_id) REFERENCES corbac_users(user_id));
CREATE TABLE corbac_contexts ( context_id VARCHAR(45) PRIMARY KEY NOT NULL, context_name VARCHAR(255) NOT NULL, context_description TEXT, CONSTRAINT ctx_name UNIQUE (context_name) );
CREATE TABLE corbac_roles (role_id VARCHAR(45) PRIMARY KEY NOT NULL, role_name VARCHAR(255) NOT NULL, role_description TEXT, is_valid INTEGER, context_id VARCHAR(45) NOT NULL, CONSTRAINT ctx_role UNIQUE( role_name, context_id), FOREIGN KEY(context_id) REFERENCES corbac_contexts(context_id) );
CREATE TABLE corbac_user_context_roles (user_id VARCHAR(45) NOT NULL, context_id VARCHAR(45) NOT NULL, role_id VARCHAR(45) NOT NULL, PRIMARY KEY (user_id, context_id, role_id), FOREIGN KEY(user_id) REFERENCES corbac_users(user_id), FOREIGN KEY (context_id) REFERENCES corbac_contexts(context_id), FOREIGN KEY(role_id) REFERENCES corbac_roles(role_id) );
CREATE TABLE corbac_resources ( resource_id VARCHAR(45) PRIMARY KEY NOT NULL, resource_name VARCHAR(255) NOT NULL, resource_label VARCHAR(255), resource_description TEXT, CONSTRAINT name_of_resource UNIQUE (resource_name));
CREATE TABLE corbac_permissions (permission_id VARCHAR(45) PRIMARY KEY NOT NULL, permission_name VARCHAR(255) NOT NULL, permission_label VARCHAR(255), permission_description TEXT, resource_id VARCHAR(45) NOT NULL, CONSTRAINT resource_permission UNIQUE (permission_name, resource_id) );
CREATE TABLE corbac_role_permissions ( role_id VARCHAR(45) NOT NULL, resource_id VARCHAR(45) NOT NULL, permission_id VARCHAR(45) NOT NULL, PRIMARY KEY (role_id, resource_id, permission_id), FOREIGN KEY(resource_id) REFERENCES corbac_resources(resource_id), FOREIGN KEY (permission_id) REFERENCES corbac_permissions(permission_id), FOREIGN KEY(role_id) REFERENCES corbac_roles(role_id));
-- 1 down
DROP TABLE corbac_role_permissions
DROP TABLE corbac_permissions
DROP TABLE corbac_resources
DROP TABLE corbac_user_context_roles
DROP TABLE corbac_roles
DROP TABLE corbac_contexts
DROP TABLE corbac_user_sessions
DROP TABLE corbac_users

@@ migrations
-- 1 up
CREATE TABLE users ( user_id INTEGER AUTO_INCREMENT, username VARCHAR(255) NOT NULL, user_password VARCHAR(200) NOT NULL, PRIMARY KEY(user_id), CONSTRAINT app_user UNIQUE (username) );
CREATE TABLE user_sessions ( user_id INTEGER, session_id VARCHAR(45) NOT NULL, access_tree TEXT, session_started INTEGER NOT NULL, PRIMARY KEY (user_id, session_id) );
CREATE TABLE contexts ( context_id INTEGER AUTO_INCREMENT, context_name VARCHAR(255) NOT NULL, context_description TEXT, PRIMARY KEY (context_id), CONSTRAINT ctx_name UNIQUE (context_name) );
CREATE TABLE roles (role_id INTEGER AUTO_INCREMENT, role_name VARCHAR(255) NOT NULL, role_description TEXT, is_valid INTEGER, context_id INTEGER, PRIMARY KEY ( role_id ), CONSTRAINT ctx_role UNIQUE( role_name, context_id) );
CREATE TABLE resources ( resource_id INTEGER AUTO_INCREMENT, resource_name VARCHAR(255) NOT NULL, resource_label VARCHAR(255), resource_description TEXT, PRIMARY KEY (resource_id), CONSTRAINT name_of_resource UNIQUE (resource_name));
CREATE TABLE permissions (permission_id INTEGER AUTO_INCREMENT, permission_name VARCHAR(255) NOT NULL, permission_label VARCHAR(255), permission_description TEXT, resource_id (INTEGER), PRIMARY KEY (permission_id), CONSTRAINT resource_permission UNIQUE (permission_name, resource_id) );
CREATE TABLE user_context_roles (user_id INTEGER AUTO_INCREMENT, context_id INTEGER, role_id INTEGER, PRIMARY KEY (user_id, context_id, role_id) );
CREATE TABLE role_permissions ( role_id INTEGER AUTO_INCREMENT, resource_id INTEGER, permission_id INTEGER, PRIMARY KEY (role_id, resource_id, permission_id);
-- 1 down
DROP TABLE user_sessions;
DROP TABLE user_context_roles;
DROP TABLE role_permissions;
DROP TABLE contexts;
DROP TABLE permissions;
DROP TABLE resources;
DROP TABLE roles;
DROP TABLE users;