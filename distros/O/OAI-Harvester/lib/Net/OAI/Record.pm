package Net::OAI::Record;

use strict;
use warnings;

=head1 NAME

Net::OAI::Record - An OAI-PMH record.

=head1 SYNOPSIS

=head1 DESCRIPTION

Net::OAI::Record objects represent the OAI records harvested by C<GetRecord()> or C<ListRecords()>
calls (an OAI record consists of the mandatory I<header>, an optional I<metadata> container 
element and zero or more I<about> containers) and also the reduced (I<header> only) ones
delivered by C<ListIdentifiers()>.

The objects are created within the processing performed by the corresponding 
L<Net::OAI::GetRecord>, L<Net:OAI::ListRecords>, and L<Net::OAI::ListIdentifiers>
filter classes. They all sit on top of (slightly misnomed) SAX filters of class
L<Net::OAI::Record::Header>. 
Please consult the documentation of that class if you are interested in writing
custom handlers.

=head1 METHODS

=head2 new()

probably don't want to instantiate this yourself

=cut

sub new {
    my ( $class, %opts ) = @_;
    return bless {
	header	    => $opts{ header },
	@{[$opts{ metadata } ? (metadata => $opts{ metadata }) : ()]},
	@{[$opts{ recorddata } ? (recorddata => $opts{ recorddata }) : ()]},
    }, ref( $class ) || $class;
}

=head2 header()

Returns the C<Net::OAI::Header> object for the OAI header element that
accompanied the record.

=cut

sub header {
    my $self = shift;
    return( $self->{ header } );
}

=head2 metadata()
=head2 recorddata()

Returns the object (SAX Handler!) used or created by the C<metadataHandler> 
rsp. C<recordHandler> filter class at the moment the OAI::Record was created, 
namely right after parsing encounters the closing OAI record tag. 

In the case of C<ListRecords> requests, a clone of the OAI::record is immediately
created (by means of L<Storable>) thus on processing by the next() method these
C<metadata()> rsp. C<recorddata()> methods will return clones of the original
handler object taken at the moment described above.

Will be C<undef> when no corresponding option was provided.

Access to the actual data if desired has to be provided by the Handler class.
Note that in the case of deleted records the I<record> element of the OAI-PMH response
must not contain a metadata container and therefore the metadataHandler 
for that record will never have been active at all.

=cut 

sub metadata {
    my $self = shift;
#   return undef unless exists $self->{ metadata };
    return $self->{ metadata } || undef;
}


sub recorddata {
    my $self = shift;
#   return undef unless exists $self->{ recorddata };
    return $self->{ recorddata } || undef;
}

=head1 AUTHOR

Ed Summers <ehs@pobox.com>

=cut


1;
