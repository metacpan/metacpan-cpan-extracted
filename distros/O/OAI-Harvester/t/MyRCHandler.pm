package MyRCHandler; 

# custom handler for testing that we can drop in our own recorddata
# handler in t/03.getrecord.t and t/50.listrecords.t

use base qw( XML::SAX::Base );

use constant {
  XMLNS_OAI => 'http://www.openarchives.org/OAI/2.0/',
  XMLNS_DC => 'http://purl.org/dc/elements/1.1/',
};

sub title { 
    my $self = shift;
    return( $self->{ title } );
}

sub OAIdentifier { 
    my $self = shift;
    return( $self->{ OAIdentifier } );
}

sub start_element {
    my ( $self, $element ) = @_; 
    if ( ($element->{ NamespaceURI } eq XMLNS_DC)
      && ($element->{ LocalName } eq 'title') ) { 
	$self->{ foundTitle } = 1;
	$self->{ title } = "";
    }
    elsif ( ($element->{ NamespaceURI } eq XMLNS_OAI)
      && ($element->{ LocalName } eq 'identifier') ) { 
	$self->{ foundOAIdentifier } = 1;
	$self->{ OAIdentifier } = "";
    }
}

sub end_element {
    my ( $self, $element ) = @_;
    if ( ($element->{ NamespaceURI } eq XMLNS_DC)
      && ($element->{ LocalName } eq 'title') ) {
	$self->{ foundTitle } = 0;
    } elsif ( ($element->{ NamespaceURI } eq XMLNS_OAI)
      && ($element->{ LocalName } eq 'identifier') ) {
	$self->{ foundOAIdentifier } = 0;
    }
}

sub characters {
    my ( $self, $characters ) = @_;
    if ( $self->{ foundTitle } ) {
	$self->{ title } .= $characters->{ Data };
    } elsif ( $self->{ foundOAIdentifier } ) {
	$self->{ OAIdentifier } .= $characters->{ Data };
    }
}

1;
