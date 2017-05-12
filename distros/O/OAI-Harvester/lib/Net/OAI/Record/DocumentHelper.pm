package Net::OAI::Record::DocumentHelper;

use strict;
use warnings;

use base qw( XML::SAX::Base );
use Carp qw( carp croak );
our $VERSION = "1.20";

=head1 NAME

Net::OAI::Record::DocumentHelper - filter class for fine tuning document events and collecting processing results

=head1 SYNOPSIS

 $filter = Net::OAI::Record::DocumentHelper->new(
    Handler => 'XML::SAX::Writer'
    provideDocumentEvents => 1,
# since XML::SAX::Writer->new() returns objects of a differentClass
    dontVerifyHandler => 1,
  );
 $records = $harvester->listRecords( 
	'metadataPrefix'  => 'oai_dc',
        'metadataHandler' => $filter;
 );


 $builder = XML::LibXML::SAX::Builder->new();
 $helper = Net::OAI::Recrd::DocumentHelper->new(
    Handler => $builder,
    provideDocumentEvents => 1,
    finalizeHook => sub { return $_[0]->finalize()->serialize() }
   );
 $records = $harvester->listRecords( 
	'metadataPrefix'  => 'oai_dc',
        'metadataHandler' => $helper;
 );
  


=head1 DESCRIPTION

This helper class acts as a SAX filter and can be used as recordHandler or
metadataHandler for Net::OAI::Harvester->listRecord() or getRecord()
requests or within a SAX filter chain.

The Handler may be a class name, in which case a new object of that
class is created on instantiation of a DocumentHelper object, or
an existing SAX filter which then will be reused. (In this case it
is your responsibility to use only filters which support the processing
of multiple documents by one instance.)

If the option C<provideDocumentEvents> is set to a true value, the filter 
will generate start_document() and end_document() events.

If the (exlusive to the previous) option C<suppressDocumentEvents> is set to 
a true value, the filter will stop start_document() and end_document() events
from propagating up the chain.

If the option C<dontVerifyHandler> is set to a true value, class sanity checks
for existing or freshly created ones are skipped.

The option C<finalizeHook> may specify a callback for postprocessing the
result just after an end_document() event has been forwarded. It is
called with two arguments, the handler object and the result of the
forwarded end_document() and should return something suitable for processing 
with L<Storable>.

=head1 METHODS

=head2 new( %options )

Creates a Handler suitable as recordHandler or metadataHandler or intermediate
filter.

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless { %opts }, ref( $class ) || $class;
    $self->{ _tagStack } = [];
    $self->{ _prefixmap } = {};
    my $handler = $opts{ Handler };
    if ( ref($handler) ) {    # active handler
#       Net::OAI::Harvester::_verifyHandler( $handler ) unless $opts{ dontVerifyHandler };
        $self->set_handler($handler);
      }
    elsif ( $opts{ dontVerifyHandler } ) {
        eval( "use $handler" );
        Net::OAI::Harvester::_fatal( "unable to locate Handler $handler in: " . 
	    join( "\n\t", @INC ) ) if $@; 
        my $instance = $handler->new();
        carp( "Handler $handler must inherit from XML::SAX::Base\n" )
            if ( ! grep { 'XML::SAX::Base' } eval( '@' . $handler . '::ISA' ) );
        $self->set_handler( $handler->new() );
      }
    else {    # instantiate from class name
        Net::OAI::Harvester::_verifyHandler( $handler );
        $self->set_handler( $handler->new() );
      };
    croak("finalizeHook must be a coderef") if $opts{ finalizeHook }
                                          and (ref($opts{ finalizeHook }) ne "CODE");
    croak("only one option of provideDocumentEvents and suppressDocumentEvents may be given")
        if $opts{ provideDocumentEvents } and $opts{ suppressDocumentEvents };
    $self->{ _inDocument } = 0;
    $self->{ _result } = undef;
    return( $self );
}

=head2 result ( ) 

Returns the result of the last end_document() forwarded to the handler,
usually this is the result of some sort of finalizing process.

=cut

sub result {
  my ( $self ) = @_;
  return $self->{ _result };
}

=head1 AUTHOR

Thomas Berger <ThB@gymel.com>

=cut

## Storable hooks

sub STORABLE_freeze {
  my ($obj, $cloning) = @_;
  return if $cloning;
  return ref($obj->{ _result }) ? ("", $obj->{ _result }) : ($obj->{ _result });   # || undef;
}

sub STORABLE_thaw {
  my ($obj, $cloning, $serialized, $listref) = @_;
  return if $cloning;
  $obj->{ _result } = ($serialized eq "") ? $listref : $serialized;
#carp "thawed @$listref";
}


## SAX handlers

sub start_document {
  my ($self, $document) = @_;
  return if $self->{ _inDocument };
  $self->{ _inDocument } = 1;
  $self->{ _result } = undef;
  my $result = $self->{ suppressDocumentEvents } ? undef : $self->SUPER::start_document( $document );
  foreach my $deferred ( values %{$self->{ _prefixmap }} ) {
       $self->SUPER::start_prefix_mapping( $deferred )};
  return $result;
}

sub end_document {
  my ($self, $document) = @_;
  return unless $self->{ _inDocument };
  $self->{ _inDocument } = 0;
  my $result = $self->{ suppressDocumentEvents } ? undef : $self->SUPER::end_document( $document );
  $self->{ _result } = $self->{ finalizeHook }
                     ? &{$self->{ finalizeHook }}($self->get_handler(), $result)
                     : $result;
  return $result;
}

sub start_prefix_mapping {
  my ($self, $mapping) = @_;
  if ( $self->{ _inDocument } ) {
      return $self->SUPER::start_prefix_mapping( $mapping )};
  $self->{ _prefixmap }->{ $mapping->{Prefix} } = $mapping;
}

sub end_prefix_mapping {
  my ($self, $mapping) = @_;
  if ( $self->{ _inDocument } ) {
      return $self->SUPER::end_prefix_mapping( $mapping )};
  delete $self->{ _prefixmap }->{ $mapping->{Prefix} };
}

sub start_element {
    my ( $self, $element ) = @_;
    push (@{$self->{ _tagStack }}, $element->{ Name });
    unless ( $self->{ _inDocument } ) {
        if ( $self->{ provideDocumentEvents } ) {
            $self->SUPER::start_document( {} );
            foreach my $deferred ( values %{$self->{ _prefixmap }} ) {
                 $self->SUPER::start_prefix_mapping( $deferred )};
          };
        $self->{ _inDocument } = 1;
      }
    return $self->SUPER::start_element( $element );
}

sub end_element {
    my ( $self, $element ) = @_;
    pop (@{$self->{ _tagStack }});
    if ( $self->{ _tagStack }->[0] ) {
        return $self->SUPER::end_element( $element );
      }
    my $elemresult = $self->SUPER::end_element( $element );
    if ( $self->{ provideDocumentEvents } ) {
        foreach my $deferred ( values %{$self->{ _prefixmap }} ) {
             $self->SUPER::end_prefix_mapping( $deferred )};
        my $docresult = $self->SUPER::end_document( {} );
        $self->{ _result } = $self->{ finalizeHook }
                           ? &{$self->{ finalizeHook }}($self->get_handler(), $docresult)
                           : $docresult;
      }
    $self->{ _inDocument } = 0;
    return $elemresult;
}

sub characters {
    my ( $self, $characters ) = @_;
    return $self->{ _inDocument } ? $self->SUPER::characters( $characters ) : undef;
}

1;

