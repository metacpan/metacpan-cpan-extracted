
package PRANG::Graph::Text;
$PRANG::Graph::Text::VERSION = '0.20';
use Moose;
use MooseX::Params::Validate;
use XML::LibXML;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	;

has 'nodeName_attr' =>
	is => "rw",
	;

has 'xmlns_attr' =>
	is => "rw",
	;

has 'extra' =>
	is => "ro",
	isa => "ArrayRef",
	lazy => 1,
	default => sub {
	my $self = shift;
	my @extra;
	if ( $self->nodeName_attr ) {
		push @extra, "";
	}
	else {
		push @extra, undef;
	}
	if ( $self->xmlns_attr ) {
		push @extra, "";
	}
	elsif ( !defined $extra[0] ) {
		pop @extra;
	}
	\@extra;
	};

sub node_ok {
    my $self = shift;
    my ( $node, $ctx ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
    );    
    
	(   $node->nodeType == XML_TEXT_NODE
			or
			$node->nodeType == XML_CDATA_SECTION_NODE
		)
		? 1 : undef;
}

sub accept {
    my $self = shift;
    my ( $node, $ctx ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
        { isa => 'Bool' },
    );    
    
	if ( $node->nodeType == XML_TEXT_NODE ) {
		($self->attrName, $node->data, @{$self->extra});
	}
	elsif ( $node->nodeType == XML_CDATA_SECTION_NODE ) {
		($self->attrName, $node->data, @{$self->extra});
	}
	else {
		$ctx->exception("expected text node", $node);
	}
}

sub complete{
	1;
}

sub expected {
	"TextNode";
}

sub output  {
    my $self = shift;
    my ( $item, $node, $ctx, $value, $slot, $name ) = pos_validated_list(
        \@_,
        { isa => 'Object' },
        { isa => 'XML::LibXML::Element' },
        { isa => 'PRANG::Graph::Context' },
        { isa => 'Item', optional => 1 },
        { isa => 'Int', optional => 1 },
        { isa => 'Str', optional => 1 },            
    );     
    
	$value //= do {
		my $attrName = $self->attrName;
		$item->$attrName;
	};
	if ( ref $value ) {
		$value = $value->[$slot];
	}
	return unless length($value//"");
	my $doc = $node->ownerDocument;
	my $tn = $self->createTextNode($doc, $value);
		
	$node->appendChild($tn);
}

with 'PRANG::Graph::Node';

1;

__END__

=head1 NAME

PRANG::Graph::Text - accept an XML TextNode

=head1 SYNOPSIS

See L<PRANG::Graph::Meta::Element> source and
L<PRANG::Graph::Node> for examples and information.

=head1 DESCRIPTION

This graph node specifies that the XML graph at this point may contain
a text node.  If it doesn't, this is considered equivalent to a
zero-length text node.

If the element only has only complex children, it will not have one of
these objects in its graph.

Along with L<PRANG::Graph::Element>, this graph node is the only type
which may actually consume input XML nodes or emit them on output.
The other node types merely change the state in the
L<PRANG::Graph::Context> object.

=head1 ATTRIBUTES

=over

=item B<attrName>

Used when emitting; specifies the method to call to retrieve the item
to be output.  Also used when parsing, to return the Moose attribute
slot for construction.

=back

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Element>,
L<PRANG::Graph::Context>, L<PRANG::Graph::Node>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

