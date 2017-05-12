
package PRANG::Graph::Context;
$PRANG::Graph::Context::VERSION = '0.18';
use 5.010;
use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;

BEGIN {
	class_type "XML::LibXML::Element";
}

has 'seq_pos' =>
	is => "rw",
	isa => "Int",
	lazy => 1,
	default => 1,
	trigger => sub {
	my $self = shift;
	$self->clear_quant;
	$self->clear_chosen;
	$self->clear_element_ok;
	},
	clearer => "clear_seq_pos",
	;

sub reset {
    my $self = shift;
    
	$self->clear_seq_pos;
}

has 'quant_found' =>
	is => "rw",
	isa => "Int",
	lazy => 1,
	default => 0,
	clearer => 'clear_quant',
	trigger => sub {
	my $self = shift;
	$self->clear_chosen;
	$self->clear_element_ok;
	},
	;

has 'chosen' =>
	is => "rw",
	isa => "Int",
	clearer => "clear_chosen",
	trigger => sub {
	$_[0]->clear_element_ok;
	}
	;

has 'element_ok' =>
	is => "rw",
	isa => "Bool",
	clearer => "clear_element_ok",
	;

# For recursion, we need to know a couple of extra things.
has 'base' =>
	is => "ro",
	isa => 'PRANG::Marshaller',
	;

has 'xpath' =>
	is => "ro",
	isa => "Str",
	;

has 'xsi' =>
	is => "rw",
	isa => "HashRef",
	default => sub { {} },
	;

has 'old_xsi' =>
	is => "rw",
	isa => "HashRef",
	default => sub { {} },
	;

has 'rxsi' =>
	is => "rw",
	isa => "HashRef",
	lazy => 1,
	default => sub {
	my $self = shift;
	+{ reverse %{ $self->xsi } };
	},
	;

has 'xsi_virgin' =>
	is => "rw",
	isa => "Bool",
	default => 1,
	;

sub thing_xmlns {
	my $thing = shift;
	return unless blessed $thing;
	my $xmlns = shift;
	if ( $thing->can("preferred_prefix") ) {
		$thing->preferred_prefix($xmlns);
	}
	elsif ( $thing->can("xmlns_prefix") ) {
		$thing->xmlns_prefix($xmlns);
	}
}

sub next_ctx {
    my $self = shift;
    my ( $xmlns, $newnode_name, $thing) = pos_validated_list(
        \@_,
        { isa => 'Maybe[Str]' },
        { isa => 'Maybe[Str]' },
        { optional => 1 },        
    );    
    
	my $prefix = $self->prefix;
	my $new_prefix;
	if ($xmlns) {
		if ( !exists $self->rxsi->{$xmlns} ) {
			$new_prefix = 1;
			$prefix = thing_xmlns($thing, $xmlns) //
				$self->base->generate_prefix($xmlns);
		}
		else {
			$prefix = $self->get_prefix($xmlns);
		}
	}
	my $nodename = (($newnode_name && $prefix) ? "$prefix:" : "") .
		($newnode_name||"text()");

	my $clone = (ref $self)->new(
		prefix => $prefix,
		base => $self->base,
		xpath => $self->xpath."/".$nodename,
		xsi => $self->xsi,
		rxsi => $self->rxsi,
	);
	if ($new_prefix) {
		$clone->add_xmlns($prefix, $xmlns);
	}
	$clone;
}

sub prefix_new {
    my $self = shift;
    my ( $prefix) = pos_validated_list(
        \@_,
        { isa => 'Str' },        
    );    
    
	!$self->xsi_virgin and not exists $self->old_xsi->{$prefix};
}

# this one is to know if the prefix was different to the parent type.
has 'prefix' =>
	is => "ro",
	isa => "Str",
	;

BEGIN { class_type "XML::LibXML::Node" }

sub get_prefix {
    my $self = shift;
    my ( $xmlns, $thing, $victim ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'Object', optional => 1 },
        { isa => 'XML::LibXML::Element', optional => 1 },
    );    
    
	if ( defined(my $prefix = $self->rxsi->{$xmlns}) ) {
		$prefix;
	}
	else {
		my $new_prefix = thing_xmlns($thing, $xmlns)
			// $self->base->generate_prefix($xmlns);
		$self->add_xmlns($new_prefix, $xmlns);
		if ($victim) {
			$victim->setAttribute(
				"xmlns:".$new_prefix,
				$xmlns,
			);
		}
		$new_prefix;
	}
}

sub add_xmlns {
    my $self = shift;
    my ( $prefix, $xmlns ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'Str' },
    );     
    
	if ( $self->xsi_virgin ) {
		$self->xsi_virgin(0);
		$self->old_xsi($self->xsi);
		$self->xsi({ %{$self->xsi}, $prefix => $xmlns });
		if ( $self->rxsi ) {
			$self->rxsi({ %{$self->rxsi}, $xmlns => $prefix });
		}
	}
	else {
		$self->xsi->{$prefix} = $xmlns;
		$self->rxsi->{$xmlns} = $prefix;
	}
}

sub get_xmlns{
    my $self = shift;
    my ( $prefix, ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );    
    
	$self->xsi->{$prefix};
}

# this is a very convenient class to put a rich and useful exception
# method on; all important methods use it, and it has just the
# information to make the error message very useful.
sub exception {
    my $self = shift;
    my ( $message, $node, $skip_ok ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'XML::LibXML::Node', optional => 1 },
        { isa => 'Bool', optional => 1 },
    );    
        
    
	my $error = PRANG::Graph::Context::Error->new(
		($node ? (node => $node) : ()),
		message => $message,
		xpath => $self->xpath,
		($skip_ok ? (skip_ok => 1) : ()),
	);
	die $error;
}

package PRANG::Graph::Context::Error;
$PRANG::Graph::Context::Error::VERSION = '0.18';
use Moose;
use MooseX::Params::Validate;

has 'node' =>
	is => "ro",
	isa => "XML::LibXML::Node",
	predicate => "has_node",
	;

has 'message' =>
	is => "ro",
	isa => "Str",
	;

has 'xpath' =>
	is => "ro",
	isa => "Str",
	;

has 'skip_ok' =>
	is => "ro",
	isa => "Bool",
	;

sub show_node {
    my $self = shift;
    
	return "" unless $self->has_node;
	my $extra = "";
	my $node = $self->node;
	if ( $node->isa("XML::LibXML::Element") ) {
		$extra = " (parsing: <".$node->nodeName;
		if ( $node->hasAttributes ) {
			$extra .= join(
				" ", "",
				map {
					$_->name."='".$_->value."'"
					} $node->attributes
			);
		}
		my @nodes = grep {
			!(  $_->isa("XML::LibXML::Comment")
				or
				$_->isa("XML::LibXML::Text") and $_->data =~ /\A\s+\Z/
				)
		} $node->childNodes;
		if (@nodes > 1
			and grep { !$_->isa("XML::LibXML::Element") }
			@nodes
			)
		{   $extra .= ">(mixed content)";
		}
		elsif (@nodes and $nodes[0]->isa("XML::LibXML::Element")) {
			$extra .= "><!-- ".@nodes
				." child XML nodes -->";
		}
		elsif ( @nodes and $nodes[0]->isa("XML::LibXML::Text") ) {
			$extra .= ">(text content)";
		}
		if ( @nodes == 0 ) {
			$extra .= " />";
		}
		else {
			$extra .= "</".$node->nodeName.">";
		}
		$extra .= ")";
	}
	elsif ( $node->isa("XML::LibXML::Text") ) {
		my $val = $node->data;
		if ( length($val) > 15 ) {
			$val = substr($val, 0, 13);
			$val .= "...";
		}
		$extra .= " (at text node: '$val')";
	}
	elsif ($node) {
		my $type = ref $node;
		$type =~ s{XML::LibXML::}{};
		$extra .= " (bogon? $type node)";
	}
	$extra;
}

sub build_error {
	my $self = shift;
	my $message = $self->message;
	my $extra = $self->show_node;
	return "$message at ".$self->xpath."$extra\n";
}

use overload
	'""' => \&build_error,
	fallback => 1;

1;

__END__

=head1 NAME

PRANG::Graph::Context - parse/emit state for Marshalling operations

=head1 SYNOPSIS

 my $context = PRANG::Graph::Context->new(
        base => PRANG::Marshaller->get($class),
        xpath => "/nodename",
    );

=head1 DESCRIPTION

This is a data class, it basically is like a loop counter for parsing
(or emitting).  Except instead of walking over a list, it 'walks' over
a tree of a certain, bound shape.

The shape of the XML Graph at each node is limited to:

  Seq -> Quant -> Choice -> Element -> ( Text | Null )

(any of the above may be absent)

There are assumptions that nodes only connect as above, and not just
in this class.

These state in this object allows the code to remember where it is.  A
new instance is created for each node which may have children for the
parsing efforts for that node.

=head1 ATTRIBUTES

=over

=item B<seq_pos>

=item B<quant_found>

=item B<chosen>

=item B<element_ok>

The above four properties are state information for any
L<PRANG::Graph::Seq>, L<PRANG::Graph::Quant>, L<PRANG::Graph::Choice>
or L<PRANG::Graph::Element> objects which exist in the graph for a
given class.  As the nodes always connect in a particular order,
setting one value will clear all of the values for the settings which
follow.

=item B<xpath>

The XML location of the current node.  Used for helpful error messages.

=item B<xsi>

=item B<rxsi>

These attributes contain mappings from XML prefixes to namespace URIs
and vice versa.  They should not be modified, as they are
copy-on-write from the parent Context objects.

=item B<old_xsi>

The B<xsi> attribute from the parent object.  Used for C<prefix_new>

=item B<xsi_virgin>

Unset the first time a prefix is defined.

=back

=head1 METHODS

This API is probably subject to quite some change.  It is mainly
provided for assisting understanding with internal code.

=head2 B<$ctx-E<gt>exception("message", $node?, $skip_ok?)>

Raise a context-sensitive exception via C<die>.  The XPath that the
current node was constructed with is appended with the nodename of the
passed node to provide an XML path for the error.

Where parsing or emitting errors happen with one of these objects
around, it should always be used for reporting the error.  The error
is a structured object (of type C<PRANG::Graph::Context::Error>) which
knows how to stringify into a readable error message.

=head2 B<next_ctx( Maybe[Str] $xmlns, Str $newnode_name, $thing? ) returns PRANG::Graph::Context>

This returns a new C<PRANG::Graph::Context> object, for the next level
of parsing.

=head2 B<get_xmlns( Str $prefix ) returns Str>

Returns the XML namespace associated with the passed prefix.

=head2 B<get_prefix( Str $xmlns, Object $thing?, XML::LibXML::Element $victim? ) returns Str>

Used for emitting.  This is an alternative to reading the C<rxsi> hash
attribute directly.  It returns the prefix for the given namespace URI
(C<$xmlns>), and if it is not already defined it will figure out based
on the type of C<$thing> what prefix to use, and add XML namespace
nodes to the C<$victim> XML namespace node.  If the C<$thing> does not
specify a default XML namespace prefix, then one is chosen for it.

=head2 B<add_xmlns( Str $prefix, Str $xmlns )>

Used for parsing.  This associates the given prefix with the given XML
namespace URI.

=head2 B<prefix_new( Str $prefix )>

This tells you whether or not the passed prefix was declared with this
Context or not.  Used for emitting.

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Attr>,
L<PRANG::Graph::Meta::Element>, L<PRANG::Marshaller>,

Implementations:

L<PRANG::Graph::Seq>, L<PRANG::Graph::Quant>, L<PRANG::Graph::Choice>,
L<PRANG::Graph::Element>, L<PRANG::Graph::Text>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut
