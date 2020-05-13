package Mojolicious::Plugin::ContextAuth::DB::Permission;

# ABSTRACT: Permission object for the ContextAuth database

use Mojo::Base -base, -signatures;

use Data::UUID;
use List::Util qw(any);
use Try::Tiny;

use feature 'postderef';
no warnings 'experimental::postderef';

has [qw'dbh permission_id permission_name permission_label permission_description resource_id error'];

sub load ($self, $id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need id" );
        return;
    }

    my $result = $self->dbh->db->select(
        corbac_permissions => [qw/permission_id permission_name permission_label permission_description resource_id/], {
            permission_id => $id,
        }
    );

    my $data = $result->hash;
    $result->finish;

    return if !$result->rows;

    my $permission = __PACKAGE__->new(
        dbh => $self->dbh,
        $data->%*,
        permission_id => $id,
    );

    return $permission;
}

sub add ($self, %params) {
    $self->error('');

    if ( any{ !$params{$_} }qw(permission_name resource_id) ) {
        $self->error('Need permission_name and resource_id');
        return;
    }

    if ( length $params{permission_name} > 255 || length $params{permission_name} < 3 ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    $params{permission_id} = Data::UUID->new->create_str;

    my $error;
    try {
        $self->dbh->db->insert( corbac_permissions => \%params);
    } 
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    my $permission = $self->load( $params{permission_id} );
    return $permission;
}

sub delete ($self, $id = $self->permission_id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need permission id" );
        return;
    }

    if ( ref $id ) {
        $self->error( "Invalid permission id" );
        return;
    }
    
    my $error;
    my $result;
    
    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_role_permissions => { permission_id => $id }
        );

        $result = $self->dbh->db->delete(
            corbac_permissions => {
                permission_id => $id,
            }
        );

        $tx->commit;
    }
    catch {
        $self->error( "Cannot delete permission: " . $_ );
        $error = 1;
    };

    return if $error;

    return $result->rows;
}

sub update ($self, @params) {
    $self->error('');
    
    my $id = @params % 2 ? shift @params : $self->permission_id;
    my %to_update = @params;

    if ( exists $to_update{permission_name} && (
        length $to_update{permission_name} > 255 ||
        length $to_update{permission_name} < 3
    )) {
        $self->error( 'Invalid parameter' );
        return;
    }

    delete $to_update{permission_id};

    my $result;
    my $error;
    try {
        $result = $self->dbh->db->update(
            corbac_permissions => \%to_update,
            { permission_id => $id }
        );
    }
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    if ( !$result->rows ) {
        $self->error( 'No permission updated' );
        return;
    }

    return $self->load( $id );
}

sub search ($self, %params) {
    $self->error('');

    my $error;
    my @permission_ids;

    try {
        my $result = $self->dbh->db->select(
            corbac_permissions => ['permission_id'] => \%params,
        );

        while ( my $next = $result->hash ) {
            push @permission_ids, $next->{permission_id};
        }
    }
    catch {
        $self->error('Cannot search for permissions');
        $error = $_;
    };

    return if $error;
    return @permission_ids;
}

sub set_roles ($self, %params) {
    $self->error('');
    
    if ( !$params{roles} ) {
        $self->error("Need roles");
        return;
    }
    
    if ( !$self->permission_id ) {
        $self->error("Need permission id");
        return;
    }

    my $count = 0;
    my $error;

    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_role_permissions => {
                permission_id  => $self->permission_id,
            }
        );

        $count = -1 if !$params{roles}->@*;

        for my $role_id ( $params{roles}->@* ) {
            my $result = $self->dbh->db->insert(
                corbac_role_permissions => {
                    role_id       => $role_id,
                    permission_id => $self->permission_id,
                    resource_id   => $self->resource_id,
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

sub roles ($self) {
    $self->error('');
    
    if ( !$self->permission_id ) {
        $self->error("Need permission id");
        return;
    }
    
    if ( ref $self->permission_id ) {
        $self->error("Invalid permission id");
        return;
    }

    my @roles;

    my $tx = $self->dbh->db->begin;

    my $result = $self->dbh->db->select(
        corbac_role_permissions => ['role_id'] => {
            permission_id  => $self->permission_id,
        }
    );

    while ( my $next = $result->hash ) {
        push @roles, $next->{role_id};
    }

    $tx->commit;

    return @roles;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth::DB::Permission - Permission object for the ContextAuth database

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $db = Mojolicious::Plugin::ContextAuth::DB->new(
        dsn => 'sqlite:' . $file,
    );

    my $permission = Mojolicious::Plugin::ContextAuth::DB::permission->new(
        dbh => $db->dbh,
    );

    my $new_permission = $permission->add(
        permission_name        => 'test',
        permission_description => 'hallo', 
    );

    my $updated_permission = $new_permission->update(
        permission_name        => 'ernie',
        permission_description => 'bert',
    );

    # create permission object with data for permission id 1
    my $found_permission = $permission->load( 1 );

    # delete permission
    $new_permission->delete;

=head1 ATTRIBUTES

=over 4

=item * dbh

=item * permission_name

=item * permission_description

=item * permission_id

=item * error

=back

=head1 METHODS

=head2 load

    # create permission object with data for permission id 1
    my $found_permission = $permission->load( 1 );

=head2 add

    my $new_permission = $permission->add(
        permissionname      => 'test',
        permission_password => 'hallo', 
    );

=head2 update

    my $updated_permission = $new_permission->update(
        permissionname      => 'ernie',
        permission_password => 'bert',
    );

=head2 delete

    $permission->delete;

=head2 set_roles

=head2 roles

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
 * bei add/update prüfen, dass permissionname noch nicht existiert
 * name darf keinen Punkt enthalten
 * bei delete auch permission_permissions löschen