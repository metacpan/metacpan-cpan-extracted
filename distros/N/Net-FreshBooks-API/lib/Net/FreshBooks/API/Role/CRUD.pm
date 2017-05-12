use strict;
use warnings;

package Net::FreshBooks::API::Role::CRUD;
$Net::FreshBooks::API::Role::CRUD::VERSION = '0.24';
use Moose::Role;
use Data::Dump qw( dump );
use Scalar::Util qw( blessed );

with 'Net::FreshBooks::API::Role::Iterator';

sub create {
    my $self   = shift;
    my $args   = shift;
    my $method = $self->method_string( 'create' );

    # add any additional argument to ourselves
    $self->$_( $args->{$_} ) for keys %$args;

    # create the arguments
    my %create_args = ();
    $create_args{$_} = $self->$_ for ( $self->field_names_rw );

    # remove arguments that have not been set (and so are undef)
    delete $create_args{$_}    #
        for grep { !defined $create_args{$_} }
        keys %create_args;

    my $fields = $self->_fields;

    foreach my $key ( keys %create_args ) {
        if (   exists $fields->{$key}->{presented_as}
            && $fields->{$key}->{presented_as} eq 'object'
            && !$create_args{$key}->_validates )
        {
            delete $create_args{$key};
        }
    }

    my $res = $self->send_request(
        {   _method         => $method,
            $self->api_name => \%create_args,
        }
    );

    my $xpath  = '//response/' . $self->id_field;
    my $new_id = $res->findvalue( $xpath );

    return $self->get( { $self->id_field => $new_id } );
}

sub update {
    my $self   = shift;
    my $args   = shift;
    my $method = $self->method_string( 'update' );

    # process any fields passed directly to this method
    my $fields = $self->_fields;
    foreach my $field ( $self->field_names_rw ) {
        $self->$field( $args->{$field} ) if exists $args->{$field};
    }

    my %args = ();
    for my $field ( $self->field_names_rw, $self->id_field ) {

        # we're not forcing fields to be objects.  for example, setting a
        # field to undef will send an empty element, which is how autobill,
        # for example, can be deleted
        if (   exists $fields->{$field}->{presented_as}
            && $fields->{$field}->{presented_as} eq 'object'
            && blessed( $self->$field ) )
        {
            next if !$self->$field->_validates;
        }
        $args{$field} = $self->$field;
    }

    $self->_fb->_log( debug => dump( \%args ) );

    my $res = $self->send_request(
        {   _method         => $method,
            $self->api_name => \%args,
        }
    );

    return $self;
}

sub delete {    ## no critic
    ## use critic
    my $self = shift;

    my $method   = $self->method_string( 'delete' );
    my $id_field = $self->id_field;

    my $res = $self->send_request(
        {   _method   => $method,
            $id_field => $self->$id_field,
        }
    );

    return 1;
}

1;

# ABSTRACT: Create, Read and Update roles

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Role::CRUD - Create, Read and Update roles

=head1 VERSION

version 0.24

=head1 SYNOPSIS

These roles are used for the more repetitive Create, Update and Delete
functions. Read functions have been broken out into the Iterator roles. See
the various modules which implement these methods for specific examples of how
these methods are used.

=head2 create( $args )

=head2 delete

Uses the id field of the current object to perform a delete operation.

=head2 update( $args )

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
