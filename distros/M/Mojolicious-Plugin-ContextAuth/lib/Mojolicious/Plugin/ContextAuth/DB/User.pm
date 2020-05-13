package Mojolicious::Plugin::ContextAuth::DB::User;

# ABSTRACT: User object for the ContextAuth database

use Mojo::Base -base, -signatures;

use Crypt::Eksblowfish::Bcrypt ();
use Crypt::URandom ();
use Data::UUID;
use List::Util qw(any);
use Try::Tiny;

use feature 'postderef';
no warnings 'experimental::postderef';

has [qw'dbh username user_password user_id error'];

sub load ($self, $id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need id" );
        return;
    }

    my $result = $self->dbh->db->select(
        corbac_users => [qw/user_id username user_password/], {
            user_id => $id,
        }
    );

    my $data = $result->hash;
    $result->finish;

    return if !$result->rows;

    my $user = __PACKAGE__->new(
        dbh => $self->dbh,
        $data->%*,
        user_id => $id,
    );

    return $user;
}

sub add ($self, %params) {
    $self->error('');

    if ( any{ !$params{$_} }qw/username user_password/ ) {
        $self->error('Need username and user_password');
        return;
    }

    my $cost     = 12;
    my $settings = '$2a' . sprintf '$%02i', $cost;

    _crypt( \%params );

    if ( length $params{username} > 255 || length $params{username} < 3 ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    $params{user_id} = Data::UUID->new->create_str;

    my $error;
    try {
        $self->dbh->db->insert( corbac_users => \%params);
    } 
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    my $user = $self->load( $params{user_id} );
    return $user;
}

sub delete ($self, $id = $self->user_id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need user id" );
        return;
    }

    if ( ref $id ) {
        $self->error( "Invalid user id" );
        return;
    }
    
    my $error;
    my $result;

    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_user_sessions => { user_id => $id },
        );

        $self->dbh->db->delete(
            corbac_user_context_roles => { user_id => $id }
        );

        $result = $self->dbh->db->delete(
            corbac_users => {
                user_id => $id,
            }
        );

        $tx->commit;
    }
    catch {
        $self->error( "Cannot delete user: " . $_ );
        $error = 1;
    };

    return if $error;
    return $result->rows;
}

sub update ($self, @params) {
    $self->error('');
    
    my $id = @params % 2 ? shift @params : $self->user_id;
    my %to_update = @params;

    if ( length $to_update{username} > 255 || length $to_update{username} < 3 ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    delete $to_update{user_id};

    _crypt( \%to_update ) if exists $to_update{user_password};

    my $result;
    my $error;
    try {
        $result = $self->dbh->db->update(
            corbac_users => \%to_update,
            { user_id => $id }
        );
    }
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    if ( !$result->rows ) {
        $self->error( 'No user updated' );
        return;
    }

    return $self->load( $id );
}

sub _crypt ( $params ) {
    my $cost     = 12;
    my $settings = '$2a' . sprintf '$%02i', $cost;

    $params->{user_password} = Crypt::Eksblowfish::Bcrypt::bcrypt(
        $params->{user_password},
        $settings . '$' . Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::URandom::urandom(16)),
    );
}

sub add_session ( $self, $session_id ) {
    $self->error('');
    
    $self->dbh->db->insert( corbac_user_sessions => {
        user_id         => $self->user_id,
        session_id      => $session_id, 
        session_started => time,
    });

    return 1;
}

sub search ($self, %params) {
    $self->error('');

    my $error;
    my @user_ids;

    try {
        my $result = $self->dbh->db->select(
            corbac_users => ['user_id'] => \%params,
        );

        while ( my $next = $result->hash ) {
            push @user_ids, $next->{user_id};
        }
    }
    catch {
        $self->error('Cannot search for users');
        $error = $_;
    };

    return if $error;
    return @user_ids;
}

sub set_context_roles ( $self, %params ) {
    $self->error('');
    
    my $user_id = $params{user_id} // $self->user_id;
    if ( !$user_id ) {
        $self->error("Need user id");
        return;
    }

    if ( ref $user_id ) {
        $self->error("Invalid user id");
        return;
    }

    if ( any{ !$params{$_} }qw/context_id roles/ ) {
        $self->error("need context_id and roles");
        return;
    }

    my $context_id = $params{context_id};

    if ( ref $context_id ) {
        $self->error("Invalid context id");
        return;
    }

    my $count = 0;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_user_context_roles => {
                user_id    => $user_id,
                context_id => $context_id,
            }
        );

        $count = -1 if !$params{roles}->@*;

        for my $role_id ( $params{roles}->@* ) {
            my $result = $self->dbh->db->insert(
                corbac_user_context_roles => {
                    user_id    => $user_id,
                    context_id => $context_id,
                    role_id    => $role_id,
                }
            );

            $count += $result->rows;
        }

        $tx->commit;
    }
    catch {
        $self->error( "Transaction error: $_" );
        $error = $_;
    };

    return if $error;
    return $count;
}

sub has_role ( $self, %params ) {
    $self->error('');
    
    my $user_id = $params{user_id} // $self->user_id;
    if ( !$user_id ) {
        $self->error("Need user id");
        return;
    }

    if ( ref $user_id ) {
        $self->error("Invalid user id");
        return;
    }

    my $context_id = $params{context_id};

    if ( !$context_id ) {
        $self->error('Need context_id');
        return;
    }

    if ( ref $context_id ) {
        $self->error("Invalid context id");
        return;
    }

    my @binds;
    my $join = '';
    if ( $params{role} ) {
        $join = 'JOIN corbac_roles r ON r.role_id = ucr.role_id AND r.role_name = ?';
        push @binds, $params{role};
    }

    my $where = '';
    if ( $params{role_id} ) {
        $where = ' ucr.role_id = ? AND ';
        push @binds, $params{role_id};
    }

    my $error;
    my $has_role;

    try {
        my $select = sprintf q~
            SELECT ucr.role_id
            FROM corbac_user_context_roles ucr
            %s
            WHERE 
                %s
                ucr.context_id = ?
                AND ucr.user_id = ?
        ~, $join, $where;

        my $result = $self->dbh->db->query(
            $select,
            @binds,
            $context_id,
            $user_id,
        );

        my $hash = $result->hash;

        return if !$hash;

        $has_role = 1;
    }
    catch {
        $self->error('Cannot determine if user has role: ' . $_);
        $error = $_;
    };

    return if $error;
    return if !$has_role;
    return 1;
}

sub context_roles ($self, %params) {
    $self->error('');
    
    my $user_id = $params{user_id} // $self->user_id;
    if ( !$user_id ) {
        $self->error("Need user id");
        return;
    }

    if ( ref $user_id ) {
        $self->error("Invalid user id");
        return;
    }

    my $context_id = $params{context_id};
    if ( !$context_id ) {
        $self->error('Need context_id');
        return;
    }

    if ( ref $context_id ) {
        $self->error("Invalid context id");
        return;
    }

    my $error;
    my @roles;

    try {
        my $select = q~
            SELECT ucr.role_id
            FROM corbac_user_context_roles ucr
            WHERE ucr.context_id = ?
                AND ucr.user_id = ?
        ~;

        my $result = $self->dbh->db->query(
            $select,
            $context_id,
            $user_id,
        );

        while ( my $next = $result->hash ) {
            push @roles, $next->{role_id};
        }
    }
    catch {
        $self->error('Cannot get context_roles: ' . $_);
        $error = $_;
    };

    return if $error;
    return sort @roles;
}

sub has_permission ($self, %params ){
    $self->error('');
    
    my $user_id = $params{user_id} // $self->user_id;
    if ( !$user_id ) {
        $self->error("Need user id");
        return;
    }

    if ( ref $user_id ) {
        $self->error("Invalid user id");
        return;
    }

    if ( any{ !$params{$_} }qw/context_id permission_id/ ) {
        $self->error('Need context_id and permission_id');
        return;
    }

    my $context_id = $params{context_id};

    if ( ref $context_id ) {
        $self->error("Invalid context id");
        return;
    }

    my $permission_id = $params{permission_id};

    if ( ref $permission_id ) {
        $self->error("Invalid permission id");
        return;
    }

    my $error;
    my $has_permission;

    try {
        my $select = q~
            SELECT ucr.user_id
            FROM corbac_user_context_roles ucr
                INNER JOIN corbac_roles r
                    ON ucr.role_id = r.role_id
                    AND ucr.context_id = r.context_id
                INNER JOIN corbac_role_permissions rp
                    ON r.role_id = rp.role_id
            WHERE ucr.context_id = ?
                AND rp.permission_id = ?
                AND ucr.user_id = ?
        ~;


        my $result = $self->dbh->db->query(
            $select,
            $context_id,
            $permission_id,
            $user_id
        );

        my $hash = $result->hash;

        return if !$hash;

        $has_permission = 1;
    }
    catch {
        $self->error('Cannot determine if user has permission: ' . $_);
        $error = $_;
    };

    return if $error;
    return if !$has_permission;
    return 1;
}

sub contexts ($self, %params) {
    $self->error('');
    
    my $user_id = $params{user_id} // $self->user_id;
    if ( !$user_id ) {
        $self->error("Need user id");
        return;
    }

    if ( ref $user_id ) {
        $self->error("Invalid user id");
        return;
    }

    my $error;
    my @contexts;

    try {
        my $select = q~
            SELECT ucr.context_id
            FROM corbac_user_context_roles ucr
            WHERE ucr.user_id = ?
        ~;

        my $result = $self->dbh->db->query(
            $select,
            $user_id,
        );

        while ( my $next = $result->hash ) {
            push @contexts, $next->{context_id};
        }
    }
    catch {
        $self->error('Cannot get contexts: ' . $_);
        $error = $_;
    };

    return if $error;
    return sort @contexts;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth::DB::User - User object for the ContextAuth database

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $db = Mojolicious::Plugin::ContextAuth::DB->new(
        dsn => 'sqlite:' . $file,
    );

    my $user = Mojolicious::Plugin::ContextAuth::DB::User->new(
        dbh => $db->dbh,
    );

    my $new_user = $user->add(
        username      => 'test',
        user_password => 'hallo', 
    );

    my $updated_user = $new_user->update(
        username      => 'ernie',
        user_password => 'bert',
    );

    # create user object with data for user id 1
    my $found_user = $user->load( 1 );

    # delete user
    $new_user->delete;

    # check if user is allowed to update the title of the project in "Project X"
    my $can_update = $found_user->has_permission(
        context_id => 123,
        permission_id => 33,
    );

    # check if user has role Y in "Project X"
    my $has_role = $found_user->has_role(
        context_id => 123,
        role_id    => 15,
    );

=head1 ATTRIBUTES

=over 4

=item * dbh

=item * username

=item * user_password

=item * user_id

=item * error

=back

=head1 METHODS

=head2 load

    # create user object with data for user id 1
    my $found_user = $user->load( 1 );

=head2 has_permission

    # check if user is allowed to update the title of the project in "Project X"
    my $can_update = $found_user->has_permission(
        context_id => 123,
        permission_id => 33,
    );

=head2 has_role

    # check if user has role Y in "Project X"
    my $has_role = $found_user->has_role(
        context_id => 123,
        role_id    => 15,
    );

=head2 add

    my $new_user = $user->add(
        username      => 'test',
        user_password => 'hallo', 
    );

=head2 update

    my $updated_user = $new_user->update(
        username      => 'ernie',
        user_password => 'bert',
    );

=head2 delete

    $user->delete;

=head2 add_session

    # add new session for the user
    my $success = $found_user->add_session(
        $session_id
    );

=head2 set_context_roles

    # set roles the user has in the given context
    my $success = $found_user->set_context_roles(
        context_id => 123,
        roles      => [    # list of role_ids
            15,
            22,
            33,
        ],
    );

=head2 context_roles

    my @roles = $user->context_roles(
        context_id => 123,
    );

Returns a list of role ids.

=head2 contexts

    my @context_ids = $user->context_roles();

Returns a list of context ids.

=head2 has_permission

    my $has_permission = $user->has_permission(
        context_id => 123,
        role_id    => 456, # or role => 'role_name'
    );

=head2 has_role

    my @roles = $user->has_role(
        context_id => 123,
        role_id    => 456, # or role => 'role_name'
    );

=head2 search

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__
TODO:
 * ID ist *kein* auto increment, da ID aus einem anderen System kommt
 * bei add/update prüfen, dass username noch nicht existiert