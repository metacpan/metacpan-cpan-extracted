package Net::OAI::GetRecord;

use strict;
use warnings;
use base qw( XML::SAX::Base Net::OAI::Base );
use Net::OAI::Record::Header;

=head1 NAME

Net::OAI::GetRecord - The results of a GetRecord OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;

    my $package;
    if ( $package = $opts{ recordHandler } ) {  
        $opts{ metadataHandler } and croak( "you may pass either a recordHandler or a metadataHandler to getRecord()" );
        delete $opts { metadataHandler };
    } elsif ( $package = $opts{ metadataHandler } ) {  
	delete $opts{ recordHandler };
    } else {
        delete $opts{ recordHandler };
	$package = $opts{ metadataHandler } = 'Net::OAI::Record::OAI_DC';
    }
    Net::OAI::Harvester::_verifyHandler( $package );

    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ header } = undef;
    $self->{ _prefixmap } = {};
    return( $self );
}

=head2 record()

return the result as Net::OAI::Record.

=cut

sub record {
    my $self = shift;
    return $self->{ record };
}

=head2 header()

Shortcut to the C<header()> method of the L<Net::OAI::Record> fetched.

=cut

sub header {
    my $self = shift;
    return $self->{ record }->header;
}

=head2 metadata()

Shortcut to the C<metadata()> method of the L<Net::OAI::Record> fetched.
The return value may be undefined in case of deleted records or if no 
metadataHandler was provided.

=cut

sub metadata {
    my $self = shift;
    return undef unless $self->{ record };
    return $self->{ metadataHandler } ? $self->{ record }->metadata() : undef;
}


=head2 recorddata()

Shortcut to the C<recorddata()> method of the L<Net::OAI::Record> fetched.
The return value may be undefined in case of deleted records or if no 
metadataHandler was provided.

=cut

sub recorddata {
    my $self = shift;
    return undef unless $self->{ record };
    return $self->{ recordHandler } ? $self->{ record }->recorddata() : undef;
}


## SAX Handlers doing about the same as those of ListRecords.pm

sub start_prefix_mapping {
  my ($self, $mapping) = @_;
  if ( $self->get_handler() ) {
      return $self->SUPER::start_prefix_mapping( $mapping )};
  $self->{ _prefixmap }->{$mapping->{ Prefix }} = $mapping;
}

sub end_prefix_mapping {
  my ($self, $mapping) = @_;
  if ( $self->get_handler() ) {
      return $self->SUPER::end_prefix_mapping( $mapping )};
  delete $self->{ _prefixmap }->{$mapping->{ Prefix }};
}

sub start_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::start_element($element) unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;

    ## if we are at the start of a new record then we need an empty 
    ## metadata object to fill up 
    if ( ($element->{ LocalName } eq 'record') ) { 
	## we store existing downstream handler so we can replace
	## it after we are done retrieving the metadata record
	$self->{ OLD_Handler } = $self->get_handler();
	my $header = $self->{ recordHandler }
		   ? Net::OAI::Record::Header->new( 
			Handler => (ref($self->{ recordHandler }) ? $self->{ recordHandler } : $self->{ recordHandler }->new()),
			fwdAll => 1,
		     )
		   : Net::OAI::Record::Header->new( 
			Handler => (ref($self->{ metadataHandler }) ? $self->{ metadataHandler } : $self->{ metadataHandler }->new()),
                        ($Net::OAI::Harvester::OLDmetadataHandler ? (fwdAll => 1) : ()),
		     );
	$self->set_handler( $header );
        foreach my $mapping ( values %{$self->{_prefixmap}} ) {
            $self->SUPER::start_prefix_mapping($mapping)};
    }
    return $self->SUPER::start_element( $element );
}

sub end_element {
    my ( $self, $element ) = @_;

    $self->SUPER::end_element( $element );
    return unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;

    ## if we've got to the end of the record we need finish up
    ## the object
    if ( $element->{ LocalName } eq 'record' ) {
	my $header = $self->get_handler();
	my $data = $header->get_handler();
	$header->set_handler( undef ); ## remove reference to $metadata
        my $record;
        if ( $self->{ recordHandler } ) {
	    $record = Net::OAI::Record->new(header => $header, recorddata => $data)
        } else {
	    $record = Net::OAI::Record->new(header => $header, metadata => $data)
	};
        $self->{ record } = $record;
	## set handler to what is was before we started processing
	## the record
	$self->set_handler( $self->{ OLD_Handler } );
      }
}

1;

