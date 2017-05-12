package Net::OAI::ResumptionToken;

use strict;
use warnings;
use base qw( XML::SAX::Base );
use Carp qw( carp );


=head1 NAME

Net::OAI::ResumptionToken - An OAI-PMH resumption token.

=head1 SYNOPSIS

=head1 DESCRIPTION

This SAX filter records resumption token elements.

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ _insideResumptionToken } = 0;
    $self->{ token } = $self->{ expirationDate } = $self->{ completeListSize } = $self->{ cursor } = undef;
    return( $self );
}

=head2 token()

(Sets and) returns the contents of the resumptionToken element.

All methods return C<undef> if no token was encountered.

=cut

sub token {
    my ( $self, $token ) = @_;
    if ( $token ) { $self->{ token } = $token; }
    return( $self->{ resumptionTokenText } );
}

=head2 expirationDate()

=cut

sub expirationDate {
    my ( $self, $date ) = @_;
    if ( $date ) { $self->{ expirationDate } = $date; }
    return( $self->{ expirationDate } );
}

=head2 completeListSize()

=cut

sub completeListSize {
    my ( $self, $size ) = @_;
    if ( $size ) { $self->{ completeListSize } = $size; }
    return( $self->{ completeListSize } );
}

=head2 cursor()

=cut 

sub cursor {
    my ( $self, $cursor ) = @_;
    if ( $cursor ) { $self->{ cursor } = $cursor; }
    return( $self->{ cursor } );
}


=head1 AUTHORS

Ed Summers <ehs@pobox.com>

=cut

## internal stuff

## all children of Net::OAI::Base should call this to make sure
## certain object properties are set
sub start_prefix_mapping {
  my ($self, $mapping) = @_;
  die "rT: self not defined" unless defined $self;
  return $self->SUPER::start_prefix_mapping( $mapping ) if $self->get_handler();
  die "rT: start_prefix_mapping @{[$mapping]} w/o Handler";
}


sub start_element { 
    my ( $self, $element ) = @_;
    return $self->SUPER::start_element( $element ) unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;

    if ( $element->{ LocalName } eq 'resumptionToken' ) {
	my $attr = $element->{ Attributes };
	$self->{ expirationDate } = $attr->{ '{}expirationDate' }{ Value } if $attr->{ '{}expirationDate' };
	$self->{ completeListSize } = $attr->{ '{}completeListSize' }{ Value } if $attr->{ '{}completeListSize' };
	$self->{ cursor } = $attr->{ '{}cursor' }{ Value } if $attr->{ '{}cursor' };
	$self->{ resumptionTokenText } = "";
	$self->{ _insideResumptionToken } = 1;
    } elsif ( $self->{ _insideResumptionToken } ) {
        carp "start of unhandled subelement ".$element->{ Name }." within resumptionToken";
    } else { 
	$self->SUPER::start_element( $element );
    }
}

sub end_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::end_element( $element ) unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;

    if ( $element->{ LocalName } eq 'resumptionToken' ) {
        Net::OAI::Harvester::debug( "caught resumption token" );
	$self->{ _insideResumptionToken } = 0;
    } elsif ( $self->{ _insideResumptionToken } ) {
        carp "end of unhandled subelement ".$element->{ Name }." within resumptionToken";
    } else { 
	$self->SUPER::end_element( $element );
    }
}

sub characters {
    my ( $self, $characters ) = @_;

    if ( $self->{ _insideResumptionToken } ) {
	$self->{ resumptionTokenText } .= $characters->{ Data };
    } else { 
	$self->SUPER::characters( $characters );
    }
}

1;

