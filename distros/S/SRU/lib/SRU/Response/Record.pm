package SRU::Response::Record;
{
  $SRU::Response::Record::VERSION = '1.01';
}
#ABSTRACT: A class for representing a result record in a searchRetrieve response.

use strict;
use warnings;
use SRU::Utils qw( error );
use SRU::Utils::XML qw( element elementNoEscape );
use Carp qw( croak );

use base qw( Class::Accessor );


sub new {
    my ($class,%args) = @_;

    ## make sure required parameters are sent
    croak( "must supply recordSchema in call to new()" ) 
        if ! exists( $args{recordSchema} );
    croak( "must supply recordData in call to new()" )
        if ! exists( $args{recordData} );

    ## set some defaults
    $args{recordPacking} = 'xml' if ! exists $args{recordPacking};

    return $class->SUPER::new( \%args );
}

SRU::Response::Record->mk_accessors( qw(
    recordSchema
    recordPacking
    recordData
    recordPosition
    extraRecordData
) );


sub asXML {
    my $self = shift;
    return 
        elementNoEscape( 'record', 
            element( 'recordSchema', $self->recordSchema() ) .
            element( 'recordPacking', $self->recordPacking() ) . 
            elementNoEscape( 'recordData', $self->recordData() ) .
            element( 'recordPosition', $self->recordPosition() ) .
            element( 'extraRecordData', $self->extraRecordData() ) 
        );
}

1;

__END__

=pod

=head1 NAME

SRU::Response::Record - A class for representing a result record in a searchRetrieve response.

=head1 SYNOPSIS

    my $record = SRU::Response::Record->new();
    $record->recordData( '<title>Huck Finn</title>' );
    $response->addRecord( $record );

=head1 DESCRIPTION

SRU::Response::Record is used to bundle up the information about
a particular metadata record in a SRU::Response::SearchRetrieve
object. Typically you'll construct a record object and add it to the
SearchRetrieve response.

=head1 METHODS

=head2 new()

You must supply the recordSchema and recordData parameters. recordPacking,
recordPosition, and extraRecordData may also be supplied.

    my $record = SRU::Response::Record->new(
        recordSchema        => 'info:srw/schema/1/dc-v1.1',
        recordData          => '<title>Huckleberry Finn</title>'
    );

=head2 recordSchema()

The URI identifier of the XML schema in which the record is encoded. Although
the request may use the server's assigned short name, the response must always
be the full URI. 

=head2 recordData()

The record itself, either as a string or embedded XML. If would like 
to pass an object in here you may do so as long as it imlements the
asXML() method.

=head2 recordPacking()

The packing used in recordData, as requested by the client or the default:
"XML".

=head2 recordPosition()

The position of the record within the result set. If you don't pass this
in recordPosition will be automaticlly calculated for you when add
or retrieve a record from a SRU::Response::SearchRetrieve object.

=head2 extraRecordData()

Any extra data associated with the record.  See the section on extensions for
more information. 

=cut

=head2 asXML()

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
