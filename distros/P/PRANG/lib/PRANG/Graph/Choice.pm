
package PRANG::Graph::Choice;
$PRANG::Graph::Choice::VERSION = '0.21';
use 5.010;
use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint;

BEGIN {
    class_type('Moose::Meta::TypeConstraint');
}

has 'choices' =>
	is => "ro",
	isa => "ArrayRef[PRANG::Graph::Node]",
	default => sub { [] },
	;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'type_map' =>
	is => "ro",
	isa => "HashRef[Str|Moose::Meta::TypeConstraint]",
	predicate => "has_type_map",
	;

has 'type_map_prefix' =>
	is => "ro",
	isa => "HashRef[Str]",
	predicate => "has_type_map_prefix",
	;

has 'xml_nodeName' =>
	is => "ro",
	isa => "Str",
	predicate => "has_xml_nodeName",
	;

has 'name_attr' =>
	is => "ro",
	isa => "Str",
	predicate => "has_name_attr",
	;

has 'xmlns_attr' =>
	is => "ro",
	isa => "Str",
	predicate => "has_xmlns_attr",
	;

has 'xmlns' =>
	is => "ro",
	isa => "Str",
	predicate => "has_xmlns",
	;
	
sub node_ok {
    my $self = shift;
    my ( $node, $ctx ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
    );        
    
	for my $choice ( @{ $self->choices } ) {
		if ( defined $choice->node_ok($node, $ctx) ) {
			return 1;
		}
	}
	return;
}

sub accept {
    my $self = shift;
    my ( $node, $ctx, $lax ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
        { isa => 'Bool', optional => 1 },
    );

	if ($ctx->chosen) {

		# this is a safe exception; the only time this graph
		# node will be called repeatedly is if it is the root
		# node for an element, due to the structure of
		# PRANG::Graph::Context
		$ctx->exception(
			"Single child node expected, multiple found",
			$node,
		);
	}

	my $num;
	my $name = $node->isa("XML::LibXML::Text")
		? ""
		: $node->localname;
	my $xmlns = length($name) && $node->namespaceURI;
	my ($key, $val, $x, $ns);
	for my $choice ( @{ $self->choices } ) {
		$num++;
		if ( defined $choice->node_ok($node, $ctx) ) {
			($key, $val, $x, $ns) = $choice->accept($node, $ctx, $lax);
		}
		if ($key) {
			$ctx->chosen($num);
			return (
				$key, $val, $x||eval{$choice->nodeName}||"",
				$ns
			);
		}
	}
	return ();
}

sub complete {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );    
    
	$ctx->chosen;
}

sub expected {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );    
    
	if ( my $num = $ctx->chosen ) {
		return $self->choices->[$num-1]->expected($ctx);
	}
	else {
		my @choices;
		for my $choice ( @{$self->choices} ) {
			push @choices, $choice->expected($ctx);
		}
		return @choices;
	}
}

our $REGISTRY =
	Moose::Util::TypeConstraints::get_type_constraint_registry();

sub output {
    my $self = shift;
    
    # First 3 args positional, rest are named
    #  Because we're making 2 validation calls, we have to use different cache keys
    my ( $item, $node, $ctx ) = pos_validated_list(
        [@_[0..2]],
        { isa => 'Object' },
        { isa => 'XML::LibXML::Element' },
        { isa => 'PRANG::Graph::Context' },
        MX_PARAMS_VALIDATE_CACHE_KEY => 'choice-output-positional',
    );
    
    my ( $value, $slot ) = validated_list(
        [@_[3..$#_]],
        value => { isa => 'Item', optional => 1 },
        slot => { isa => 'Int', optional => 1 },
        MX_PARAMS_VALIDATE_CACHE_KEY => 'choice-output-named',
    );

	my $an = $self->attrName;
	$value //= $item->$an;
	my ($name, $xmlns);
	if ( $self->has_name_attr || $self->has_xmlns_attr ) {
		if ( $self->has_name_attr ) {
			my $x = $self->name_attr;
			$name = $item->$x;
			if ( defined $slot ) {
				$name = $name->[$slot];
			}
		}
		else {
			$name = $self->xml_nodeName // $an;
		}
		if ( $self->has_xmlns_attr ) {
			my $attr_getter = $self->xmlns_attr;
			$xmlns = $item->$attr_getter;
			if ( defined $slot ) {
				$xmlns = $xmlns->[$slot];
			}
		}
		else {
			$xmlns = $self->xmlns // "";
		}
	}
	elsif ( $self->has_type_map ) {
		my $map = $self->type_map;
		my $nodeCount = 0;
		for my $element ( keys %$map ) {
			my $type = $map->{$element};
			if ( !ref $type ) {
				$type = $map->{$element} =
					$REGISTRY->get_type_constraint($type);
			}
			
			if ( $type->check($value) ) {
				$name = $element;
				$nodeCount++;
			}
			
			if ($nodeCount > 1) {
                $ctx->exception("More than 1 node type matched for value: '$value' " .
                    "You need a stricter type definition for your xml_nodeName map, or PRANG can't figure out which element name to emit"); 
			}
		}
	}
	
	if ( !defined $name ) {
		$ctx->exception(
			"don't know what to serialize $value to for slot "
				.$self->attrName
		);
	}
	if ( length $name ) {
		if ( $self->has_type_map_prefix and $name =~ /(.*):(.*)/) {
			$name = $2;
			$xmlns = $self->type_map_prefix->{$1};
		}
		my $found;
		for my $choice ( @{ $self->choices } ) {
			if ($xmlns) {
				next unless $choice->has_xmlns;
				next unless $choice->xmlns eq $xmlns or
						$choice->xmlns eq "*";
			}
			next unless $choice->nodeName eq $name or
					$choice->nodeName eq "*";
			$found++;
			$choice->output(
				$item,$node,$ctx,
				value => $value,
				(defined $slot ? (slot => $slot) : ()),
				name => $name,
				(defined $xmlns ? (xmlns => $xmlns) : ()),
			);
			last;
		}
		if ( !$found ) {
			$ctx->exception(
				"don't know what to serialize $value to for slot "
					.$self->attrName
					." (looked for '$name' node"
					.(
					$xmlns?" xmlns='$xmlns'":""
					)
					.")",
			);
		}
	}
	else {

		# textnode ... jfdi
		my $tn = $self->createTextNode($node->ownerDocument, $value);
		$node->appendChild($tn);
	}
}

with 'PRANG::Graph::Node';

1;

__END__

=head1 NAME

PRANG::Graph::Choice - accept multiple discrete node types

=head1 SYNOPSIS

See L<PRANG::Graph::Meta::Element> source and
L<PRANG::Graph::Node> for examples and information.

=head1 DESCRIPTION

This graph node specifies that the XML graph at this point may be one
of a list of text nodes or elements, depending on the type of entries
in the B<choices> property.

If there is only one type of node allowed then the element does not
have one of these objects in their graph.

=head1 ATTRIBUTES

=over

=item B<ArrayRef[PRANG::Graph::Node] choices>

This property provides the next portion of the XML Graph.  Depending
on the type of entry, it will accept and emit nodes of a particular
type.

Entries must be one of L<PRANG::Graph::Element>, or
L<PRANG::Graph::Text>.

=item B<HashRef[Str|Moose::Meta::TypeConstraint] type_map>

This map is used for emitting.  It maps from the localname of the XML
node to the type which that localname is appropriate for.  This map
also needs to include the XML namespace, that it doesn't is currently a bug.

=item B<Str name_attr>

Used when emitting; avoid type-based selection and instead retrieve
the name of the XML node from this attribute.

=item B<attrName>

Used when emitting; specifies the method to call to retrieve the item
to be output.

=back

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Element>,
L<PRANG::Graph::Context>, L<PRANG::Graph::Node>

Lower order L<PRANG::Graph::Node> types:

L<PRANG::Graph::Element>, L<PRANG::Graph::Text>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

