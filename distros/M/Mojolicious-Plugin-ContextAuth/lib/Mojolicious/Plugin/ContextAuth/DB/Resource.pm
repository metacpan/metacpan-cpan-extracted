package Mojolicious::Plugin::ContextAuth::DB::Resource;

# ABSTRACT: Resource object for the ContextAuth database

use Mojo::Base -base, -signatures;

use Data::UUID;
use List::Util qw(any);
use Try::Tiny;

use feature 'postderef';
no warnings 'experimental::postderef';

has [qw'dbh resource_id resource_name resource_description resource_label error'];

sub load ($self, $id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need id" );
        return;
    }

    my $result = $self->dbh->db->select(
        corbac_resources => [qw/resource_id resource_name resource_description resource_label/], {
            resource_id => $id,
        }
    );

    my $data = $result->hash;
    $result->finish;

    return if !$result->rows;

    my $resource = __PACKAGE__->new(
        dbh => $self->dbh,
        $data->%*,
        resource_id => $id,
    );

    return $resource;
}

sub add ($self, %params) {
    $self->error('');

    if ( !$params{resource_name} ) {
        $self->error('Need resource_name');
        return;
    }

    for my $key ( qw/resource_name resource_description/ ) {
        if ( exists $params{$key} && length $params{$key} > 255 ) {
            $self->error( 'Invalid parameter' );
            return;
        }
    }

    if ( length $params{resource_name} < 3 ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    $params{resource_id} = Data::UUID->new->create_str;

    my $error;
    try {
        $self->dbh->db->insert( corbac_resources => \%params);
    } 
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    my $resource = $self->load( $params{resource_id} );
    return $resource;
}

sub delete ($self, $id = $self->resource_id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need resource id" );
        return;
    }

    if ( ref $id ) {
        $self->error( "Invalid resource id" );
        return;
    }

    my $error;
    my $result;
    
    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_role_permissions => { resource_id => $id },
        );

        $self->dbh->db->delete(
            corbac_permissions => { resource_id => $id }
        );

        $result = $self->dbh->db->delete(
            corbac_resources => {
                resource_id => $id,
            }
        );

        $tx->commit;
    }
    catch {
        $self->error( "Cannot delete resource: " . $_ );
        $error = 1;
    };

    return if $error;
    return $result->rows;
}

sub update ($self, @params) {
    $self->error('');
    
    my $id = @params % 2 ? shift @params : $self->resource_id;
    my %to_update = @params;

    if ( exists $to_update{resource_name} && (
        length $to_update{resource_name} > 255 ||
        length $to_update{resource_name} < 3
     ) ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    delete $to_update{resource_id};

    my $result;
    my $error;
    try {
        $result = $self->dbh->db->update(
            corbac_resources => \%to_update,
            { resource_id => $id }
        );
    }
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;
    return $self->load( $id );
}

sub search ($self, %params) {
    $self->error('');

    my $error;
    my @resource_ids;

    try {
        my $result = $self->dbh->db->select(
            corbac_resources => ['resource_id'] => \%params,
        );

        while ( my $next = $result->hash ) {
            push @resource_ids, $next->{resource_id};
        }
    }
    catch {
        $self->error('Cannot search for resources');
        $error = $_;
    };

    return if $error;
    return @resource_ids;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth::DB::Resource - Resource object for the ContextAuth database

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $db = Mojolicious::Plugin::ContextAuth::DB->new(
        dsn => 'sqlite:' . $file,
    );

    my $resource = Mojolicious::Plugin::ContextAuth::DB::resource->new(
        dbh => $db->dbh,
    );

    my $new_resource = $resource->add(
        resource_name        => 'test',
        resource_description => 'hallo', 
    );

    my $updated_resource = $new_resource->update(
        resource_name        => 'ernie',
        resource_description => 'bert',
    );

    # create resource object with data for resource id 1
    my $found_resource = $resource->load( 1 );

    # delete resource
    $new_resource->delete;

=head1 ATTRIBUTES

=over 4

=item * dbh

=item * resource_name

=item * resource_description

=item * resource_id

=item * error

=back

=head1 METHODS

=head2 load

    # create resource object with data for resource id 1
    my $found_resource = $resource->load( 1 );

=head2 add

    my $new_resource = $resource->add(
        resourcename      => 'test',
        resource_password => 'hallo', 
    );

=head2 update

    my $updated_resource = $new_resource->update(
        resourcename      => 'ernie',
        resource_password => 'bert',
    );

=head2 delete

    $resource->delete;

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
 * bei add/update prüfen, dass resourcename noch nicht existiert
 * name darf keinen Punkt enthalten
 * bei delete auch role_resources, resources löschen