package Net::OAI::ListMetadataFormats;

use strict;
use warnings;
use base qw( XML::SAX::Base Net::OAI::Base );
use Carp qw( carp );

=head1 NAME

Net::OAI::ListMetadataFormats - Results of the ListMetadataFormats OAI-PMH verb.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless \%opts, ref( $class ) || $class;
    $self->{ _insideList } = 0;
    $self->{ metadataPrefixes } = [];
    $self->{ namespaces } = [];
    $self->{ schemas } = [];
    return( $self );
}

=head2 prefixes()

=cut

sub prefixes() {
    my $self = shift;
    return( @{ $self->{ metadataPrefixes } } );
}

=head2 namespaces()

=cut

sub namespaces {
    my $self = shift;
    return( @{ $self->{ namespaces } } );
}

=head2 namespaces_byprefix()

Returns the namespace URI associated to a given metadataPrefix.

=cut

sub namespaces_byprefix {
    my ($self, $prefix) = @_;
    return $self->{namespaces_byprefix}->{$prefix};
}


=head2 schemas()

=cut

sub schemas {
    my $self = shift;
    return( @{ $self->{ schemas } } );
}

=head2 schemas_byprefix()

Returns the schema URI associated to a given metadataPrefix.

=cut

sub schemas_byprefix {
    my ($self, $prefix) = @_;
    return $self->{schemas_byprefix}->{$prefix};
}

# SAX Handlers

sub start_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::start_element($element) unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;  # should be error?

    if ( $element->{ LocalName } eq 'ListMetadataFormats' ) { 
	$self->{ _insideList } = 1;
    } elsif ( $self->{ _insideList } ) {
    } elsif ( $element->{ LocalName } eq 'OAI-PMH' ) {
    } else {
        carp "who am I? (".$element->{ LocalName }.")";
	$self->SUPER::start_element( $element );
    }
    push( @{ $self->{ tagStack } }, $element->{ LocalName } );
}

sub end_element {
    my ( $self, $element ) = @_;
    return $self->SUPER::end_element($element) unless $element->{NamespaceURI} eq Net::OAI::Harvester::XMLNS_OAI;  # should be error?

    my $name = $element->{ LocalName };
    if ( $name eq 'ListMetadataFormats' ) {
	$self->{ _insideList } = 0;
    } elsif ( $name eq 'metadataFormat' ) {
        my $nspf = delete $self->{ _currpf };
        $self->{ namespaces_byprefix }->{ $nspf } = delete $self->{ _currns };
        $self->{ schemas_byprefix }->{ $nspf } = delete $self->{ _currxs };
    } elsif ( $name eq 'metadataPrefix' ) {
	push( @{ $self->{ metadataPrefixes } }, $self->{ metadataPrefix } );
        $self->{ _currpf } = $self->{ metadataPrefix };
	$self->{ metadataPrefix } = '';
    } elsif ( $name eq 'schema' ) {
        push( @{ $self->{ schemas } }, $self->{schema } );
        $self->{ _currxs } = $self->{ schema };
        $self->{ schema } = '';
    } elsif ( $name eq 'metadataNamespace' ) {
        push( @{ $self->{ namespaces } }, $self->{ metadataNamespace } );
        $self->{ _currns } = $self->{ metadataNamespace };
        $self->{ metadataNamespace } = '';
    } elsif ( $self->{ _insideList } ) {
        carp "who am I? ($name)";
    } elsif ( $element->{ LocalName } eq 'OAI-PMH' ) {
    } else {
        carp "who am I? ($name)";
	$self->SUPER::end_element( $element );
    }
    pop( @{ $self->{ tagStack } } );
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ _insideList } ) {
        $self->{ $self->{ tagStack }[-1] } .= $characters->{ Data }
    } else {
        $self->SUPER::characters( $characters )};
}

1;
