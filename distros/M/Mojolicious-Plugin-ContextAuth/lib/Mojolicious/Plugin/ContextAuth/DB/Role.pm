package Mojolicious::Plugin::ContextAuth::DB::Role;

# ABSTRACT: Role object for the ContextAuth database

use Mojo::Base -base, -signatures;
use List::Util qw(any);
use Try::Tiny;

use Mojolicious::Plugin::ContextAuth::DB::Permission;

use feature 'postderef';
no warnings 'experimental::postderef';

has [qw'dbh role_id role_name role_description context_id is_valid error'];

sub load ($self, $id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need id" );
        return;
    }

    my $result = $self->dbh->db->select(
        corbac_roles => [qw/role_id role_name role_description context_id is_valid/], {
            role_id => $id,
        }
    );

    my $data = $result->hash;
    $result->finish;

    return if !$result->rows;

    my $role = __PACKAGE__->new(
        dbh => $self->dbh,
        $data->%*,
        role_id => $id,
    );

    return $role;
}

sub add ($self, %params) {
    $self->error('');

    if ( any{ !$params{$_} }qw(role_name context_id) ) {
        $self->error('Need role_name and context_id');
        return;
    }

    if ( length $params{role_name} > 255 || length $params{role_name} < 3 ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    $params{role_id} = Data::UUID->new->create_str;

    my $error;
    try {
        $self->dbh->db->insert( corbac_roles => \%params);
    } 
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    my $role = $self->load( $params{role_id} );
    return $role;
}

sub delete ($self, $id = $self->role_id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need role id" );
        return;
    }

    if ( ref $id ) {
        $self->error( "Invalid role id" );
        return;
    }

    my $error;
    my $result;

    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_role_permissions => { role_id => $id },
        );

        $self->dbh->db->delete(
            corbac_user_context_roles => { role_id => $id }
        );

        $result = $self->dbh->db->delete(
            corbac_roles => {
                role_id => $id,
            }
        );

        $tx->commit;
    }
    catch {
        $self->error( "Cannot delete role: " . $_ );
        $error = 1;
    };

    return if $error;
    return $result->rows;
}

sub update ($self, @params) {
    $self->error('');
    
    my $id = @params % 2 ? shift @params : $self->role_id;
    my %to_update = @params;

    if ( exists $to_update{role_name} && (
        length $to_update{role_name} > 255 ||
        length $to_update{role_name} < 3 )
    ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    delete $to_update{role_id};

    my $result;
    my $error;
    try {
        $result = $self->dbh->db->update(
            corbac_roles => \%to_update,
            { role_id => $id }
        );
    }
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    if ( !$result->rows ) {
        $self->error( 'No role updated' );
        return;
    }

    return $self->load( $id );
}

sub search ($self, %params) {
    $self->error('');

    my $error;
    my @role_ids;

    try {
        my $result = $self->dbh->db->select(
            corbac_roles => ['role_id'] => \%params,
        );

        while ( my $next = $result->hash ) {
            push @role_ids, $next->{role_id};
        }
    }
    catch {
        $self->error('Cannot search for roles');
        $error = $_;
    };

    return if $error;
    return @role_ids;
}

sub set_context_users ($self, %params) {
    $self->error('');

    my $role_id = $params{role_id} // $self->role_id;
    if ( !$role_id ) {
        $self->error("Need role id");
        return;
    }

    if ( ref $role_id ) {
        $self->error("Invalid role id");
        return;
    }

    if ( any{!$params{$_} }qw/context_id users/ ) {
        $self->error( "Need context_id and users" );
        return;
    }

    my $context_id = $params{context_id};

    if ( ref $context_id ) {
        $self->error( "Invalid context id" );
        return;
    }

    my $rows = 0;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_user_context_roles => {
                role_id    => $role_id,
                context_id => $context_id,
            }
        );

        $rows = -1 if !$params{users}->@*;

        for my $user_id ( $params{users}->@* ) {
            my $result = $self->dbh->db->insert(
                corbac_user_context_roles => {
                    user_id    => $user_id,
                    role_id    => $role_id,
                    context_id => $context_id,
                }
            );

            $rows += $result->rows;
        }

        $tx->commit;
    }
    catch {
        $self->error( "Transaction error: $_" );
        $error = $_;
    };

    return if $error;
    return $rows;
}

sub context_users ($self, %params) {
    $self->error('');

    my $role_id = $params{role_id} // $self->role_id;
    if ( !$role_id ) {
        $self->error("Need role id");
        return;
    }

    if ( ref $role_id ) {
        $self->error("Invalid role id");
        return;
    }

    my $context_id = $params{context_id};
    if ( !$context_id ) {
        $self->error( "No context id given" );
        return;
    }

    if ( ref $context_id ) {
        $self->error( "Invalid context id" );
        return;
    }

    my @users;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        my $result = $self->dbh->db->select(
            corbac_user_context_roles => ['user_id'] => {
                context_id => $context_id,
                role_id    => $role_id,
            }
        );
        
        while ( my $next = $result->hash ) {
            push @users, $next->{user_id};
        }

        $tx->commit;
    }
    catch {
        $self->error( "Cannot get list of context users: $_" );
        $error = $_;
    };

    return if $error;
    return @users;
}

sub set_permissions ($self, %params) {
    $self->error('');

    my $role_id = $params{role_id} // $self->role_id;
    if ( !$role_id ) {
        $self->error("Need role id");
        return;
    }

    if ( ref $role_id ) {
        $self->error("Invalid role id");
        return;
    }

    if ( any{!$params{$_} }qw/permissions/ ) {
        $self->error( "Need permissions" );
        return;
    }

    my $perm_object = Mojolicious::Plugin::ContextAuth::DB::Permission->new( dbh => $self->dbh );

    my $rows = 0;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_role_permissions => {
                role_id => $role_id,
            }
        );

        $rows = -1 if !$params{permissions}->@*;

        PERMISSION_ID:
        for my $permission_id ( $params{permissions}->@* ) {
            next PERMISSION_ID if ref $permission_id;
            
            my $permission = $perm_object->load( $permission_id );

            next PERMISSION_ID if !$permission;

            my $result = $self->dbh->db->insert(
                corbac_role_permissions => {
                    permission_id => $permission_id,
                    role_id       => $role_id,
                    resource_id   => $permission->resource_id,
                }
            );

            $rows += $result->rows;
        }

        $tx->commit;
    }
    catch {
        $self->error( "Transaction error: $_" );
        $error = $_;
    };

    return if $error;
    return $rows;
}

sub permissions ($self, %params) {
    $self->error('');

    my $role_id = $params{role_id} // $self->role_id;
    if ( !$role_id ) {
        $self->error("Need role id");
        return;
    }

    if ( ref $role_id ) {
        $self->error("Invalid role id");
        return;
    }

    my @permissions;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        my $result = $self->dbh->db->select(
            corbac_role_permissions => ['permission_id'] => {
                role_id => $role_id,
            }
        );
        
        while ( my $next = $result->hash ) {
            push @permissions, $next->{permission_id};
        }

        $tx->commit;
    }
    catch {
        $self->error( "Transaction error: $_" );
        $error = $_;
    };

    return if $error;
    return @permissions;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth::DB::Role - Role object for the ContextAuth database

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $db = Mojolicious::Plugin::ContextAuth::DB->new(
        dsn => 'sqlite:' . $file,
    );

    my $role = Mojolicious::Plugin::ContextAuth::DB::role->new(
        dbh => $db->dbh,
    );

    my $new_role = $role->add(
        role_name        => 'test',
        role_description => 'hallo', 
    );

    my $updated_role = $new_role->update(
        role_name        => 'ernie',
        role_description => 'bert',
    );

    # create role object with data for role id 1
    my $found_role = $role->load( 1 );

    # delete role
    $new_role->delete;

=head1 ATTRIBUTES

=over 4

=item * dbh

=item * role_name

=item * role_description

=item * role_id

=item * error

=back

=head1 METHODS

=head2 load

    # create role object with data for role id 1
    my $found_role = $role->load( 1 );

=head2 add

    my $new_role = $role->add(
        rolename      => 'test',
        role_password => 'hallo', 
    );

=head2 update

    my $updated_role = $new_role->update(
        rolename      => 'ernie',
        role_password => 'bert',
    );

=head2 delete

    $role->delete;

=head2 search

Search for roles...

    my @role_ids = $role->search(); # get all roles
    my @role_ids = $role->search(   # get all roles for a context
        context_id => 123,
    );

    my @role_ids = $role->search(
        role_name => { 'LIKE' => 'project%' },
    )

Returns a list of role ids if roles are found.

=head2 set_context_users

=head2 set_permissions

=head2 context_users

=head2 permissions

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__
TODO:
 * bei add/update prüfen, dass rolename noch nicht existiert
 * name darf keinen Punkt enthalten