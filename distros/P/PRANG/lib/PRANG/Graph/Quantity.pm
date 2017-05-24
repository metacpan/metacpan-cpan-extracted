
package PRANG::Graph::Quantity;
$PRANG::Graph::Quantity::VERSION = '0.20';
use Moose;
use MooseX::Params::Validate;

has 'min' =>
	is => "ro",
	isa => "Int",
	predicate => "has_min",
	;

has 'max' =>
	is => "ro",
	isa => "Int",
	predicate => "has_max",
	;

has 'child' =>
	is => "ro",
	isa => "PRANG::Graph::Node",
	required => 1,
	;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

sub accept_many {1}

sub accept {
    my $self = shift;
    my ( $node, $ctx, $lax ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
        { isa => 'Bool', optional => 1 },
    );    
    
	my $found = $ctx->quant_found;
	my $ok = defined $self->child->node_ok($node, $ctx);
	return if not $ok;
	my ($key, $value, $x, $ns) = $self->child->accept($node, $ctx, $lax)
		or $ctx->exception(
		"internal error: node ok, but then not accepted?",
		$node,
		);
	$found++;
	$ctx->quant_found($found);
	if ( $self->has_max and $found > $self->max ) {
		$ctx->exception("node appears too many times", $node);
	}
	($key, $value, $x, $ns);
}

sub complete {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );    
    
	my $found = $ctx->quant_found;
	return !( $self->has_min and $found < $self->min );
}

sub expected {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );    
    
	my $desc;
	if ( $self->has_min ) {
		if ( $self->has_max ) {
			$desc = "between ".$self->min." and ".$self->max;
		}
		else {
			$desc = "at least ".$self->min;
		}
	}
	else {
		if ( $self->has_max ) {
			$desc = "optionally up to ".$self->max;
		}
		else {
			$desc = "zero or more";
		}
	}
	my @expected = $self->child->expected($ctx);
	return("($desc of: ", @expected, ")");
}

sub output {
    my $self = shift;
    my ( $item, $node, $ctx ) = pos_validated_list(
        \@_,
        { isa => 'Object' },
        { isa => 'XML::LibXML::Element' },
        { isa => 'PRANG::Graph::Context' },
    ); 
    
	my $attrName = $self->attrName;
	my $val = $item->$attrName;
	if ( $self->has_max and $self->max == 1 ) {

		# this is an 'optional'-type thingy
		if ( defined $val ) {
			$self->child->output($item,$node,$ctx,value => $val);
		}
	}
	else {

		# this is an arrayref-type thingy
		if ( !$val and !$self->has_min ) {

			# ok, that's fine
		}
		elsif ( $val and (ref($val)||"") ne "ARRAY" ) {

			# that's not
			die "item $item / slot $attrName is $val, not"
				."an ArrayRef";
		}
		else {
			for ( my $i = 0; $i <= $#$val; $i++) {
				$ctx->quant_found($i+1);
				$self->child->output(
					$item,$node,$ctx,
					value => $val->[$i],
					slot => $i,
				);
			}
		}
	}
}

with 'PRANG::Graph::Node';

1;

__END__

=head1 NAME

PRANG::Graph::Quantity - a bounded quantity of graph nodes

=head1 SYNOPSIS

See L<PRANG::Graph::Meta::Element> source and
L<PRANG::Graph::Node> for examples and information.

=head1 DESCRIPTION

This graph node specifies that the XML graph at this point has a
quantity of text nodes, elements or element choices depending on the
type of entries in the B<child> property.

If the quantity is always 1, that is, the element is required and may
only appear one, then the element does not have one of these objects
in their graph.

=head1 ATTRIBUTES

=over

=item B<PRANG::Graph::Node child>

The B<child> property provides the next portion of the XML Graph.
Depending on the type of entry, it will accept and emit nodes in a
particular way.

Entries must be one of L<PRANG::Graph::Choice>,
L<PRANG::Graph::Element>, or L<PRANG::Graph::Text>.

=item B<Int min>

=item B<Int max>

Bounds on the number of times this graph node will match.

=item B<attrName>

Used when emitting; specifies the method to call to retrieve the item
to be output.

=back

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Element>,
L<PRANG::Graph::Context>, L<PRANG::Graph::Node>

Lower order L<PRANG::Graph::Node> types:

L<PRANG::Graph::Choice>, L<PRANG::Graph::Element>,
L<PRANG::Graph::Text>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

