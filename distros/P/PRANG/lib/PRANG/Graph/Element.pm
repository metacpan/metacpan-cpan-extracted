
package PRANG::Graph::Element;
$PRANG::Graph::Element::VERSION = '0.20';
use 5.010;
use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use XML::LibXML;

BEGIN {
	class_type "XML::LibXML::Node";
	class_type "XML::LibXML::Element";
}

has 'xmlns' =>
	is => "ro",
	isa => "Str",
	predicate => "has_xmlns",
	;

has 'nodeName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'nodeClass' =>
	is => "ro",
	isa => "Str",
	predicate => "has_nodeClass",
	;

has 'nodeName_attr' =>
	is => "rw",
	isa => "Str",
	predicate => "has_nodeName_attr",
	;

has 'xmlns_attr' =>
	is => "rw",
	isa => "Str",
	predicate => "has_xmlns_attr",
	;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'contents' =>
	is => "rw",
	isa => "PRANG::Graph::Node",
	predicate => "has_contents",
	;

sub node_ok {
    my $self = shift;
    my ( $node, $ctx ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
    );    
    
	return unless $node->nodeType == XML_ELEMENT_NODE;
	my $got_xmlns;

	if ($self->has_xmlns
		or
		($node->prefix||"") ne ($ctx->prefix||"")
		)
	{   my $prefix = $node->prefix//"";
		$got_xmlns = $ctx->xsi->{$prefix};
		if ( !defined $got_xmlns ) {
			$got_xmlns = $node->getAttribute(
				"xmlns".(length $prefix?":$prefix":"")
			);
		}
		my $wanted_xmlns = ($self->xmlns||"");
		if ($got_xmlns
			and $wanted_xmlns ne "*"
			and
			$got_xmlns ne $wanted_xmlns
			)
		{   return;
		}
	}
	my ($ret_nodeName, $ret_xmlns) = ("", "");
	my $wanted_nodeName = $self->nodeName;
	if ($wanted_nodeName ne "*"
		and $wanted_nodeName ne $node->localname
		)
	{   return;
	}
	if ( $self->has_nodeName_attr ) {
		$ret_nodeName = $node->localname;
	}
	if ( $self->has_xmlns_attr ) {
		$ret_xmlns = $got_xmlns;
	}
	if (wantarray) {
		return ($ret_nodeName, $ret_xmlns);
	}
	else {
		return $ret_nodeName;
	}
}

sub accept {
    my $self = shift;
    my ( $node, $ctx, $lax ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'PRANG::Graph::Context' },
        { isa => 'Bool', optional => 1 },
    );    
    
	my ($ret_nodeName, $xmlns) = $self->node_ok($node, $ctx);
	if ( !defined $ret_nodeName ) {

		# ok, not right, so figure out what we did want, in
		# the context of the incoming document.
		my $wanted_xmlns = ($self->xmlns||"");
		my $wanted_prefix = $ctx->get_prefix($wanted_xmlns);

		my $nodeName = $self->nodeName;
		if ( $wanted_prefix ne "" ) {
			$nodeName = "$wanted_prefix:$nodeName";
			if ( $ctx->prefix_new($wanted_prefix) ) {
				$nodeName .= " xmlns:$wanted_prefix="
					."\"$wanted_xmlns\"";
			}
		}
		$ctx->exception(
			"invalid element; expected '$nodeName'",
			$node, 1,
		);
	}
	undef($ret_nodeName) if !length($ret_nodeName);
	if ( $self->has_nodeClass ) {

		# general nested XML support
		my $marshaller = $ctx->base->get($self->nodeClass);
		my $value = (
			$marshaller
			? $marshaller->marshall_in_element(
				$node,
				$ctx,
				$lax,
				)
			: $node
		);
		$ctx->element_ok(1);
		return ($self->attrName => $value, $ret_nodeName, $xmlns);
	}
	else {

		# XML data types
		my $type = $self->has_contents
			?
			"XML data"
			: "presence-only";
		if ($node->hasAttributes) {
			$ctx->exception(
				"Superfluous attributes on $type node",
				$node
			);
		}
		if ( $self->has_contents ) {

			# simple types, eg Int, Str
			my (@childNodes) = grep {
				!(  $_->isa("XML::LibXML::Comment")
					or
					$_->isa("XML::LibXML::Text")
					and $_->data =~ /\A\s+\Z/
					)
			} $node->childNodes;

			if ( @childNodes > 1 ) {

				# we could maybe merge CDATA nodes...
				$ctx->exception(
					"Too many child nodes for $type node",
					$node,
				);
			}
			my $value;
			if ( !@childNodes ) {
				$value = "";
			}
			else {
				(undef, $value) = $self->contents->accept(
					$childNodes[0],
					$ctx,
					$lax,
				);
			}
			$ctx->element_ok(1);
			return ($self->attrName => $value, $ret_nodeName, $xmlns);
		}
		else {

			# boolean
			if ( $node->hasChildNodes ) {
				$ctx->exception(
					"Superfluous child nodes on $type node",
					$node,
				);
			}
			$ctx->element_ok(1);
			return ($self->attrName => 1, $ret_nodeName, $xmlns);
		}
	}
}

sub complete {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );    
    
	$ctx->element_ok;
}

sub expected {
    my $self = shift;
    my ( $ctx ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph::Context' },
    );   
    
	my $prefix = "";
	my $nodename = $self->nodeName;
	if ( $self->has_xmlns ) {
		my $xmlns = eval { $self->nodeClass->xmlns } ||
			$self->xmlns;
		if ( $prefix = $ctx->rxsi->{$xmlns} ) {
			$prefix .= ":";
		}
		else {
			$prefix = $ctx->get_prefix($xmlns);
			$nodename .= " xmlns:$prefix='$xmlns'";
			$prefix .= ":";
		}
	}
	return "<$prefix$nodename".(
		$self->has_nodeClass
		?"..."
		:
			$self->has_contents?"":"/"
		)
		.">";
}

sub output  {
    my $self = shift;
    
    # First 3 args positional, rest are named
    #  Because we're making 2 validation calls, we have to use different cache keys
    my ( $item, $node, $ctx ) = pos_validated_list(
        [@_[0..2]],
        { isa => 'Object' },
        { isa => 'XML::LibXML::Element' },
        { isa => 'PRANG::Graph::Context' },
        MX_PARAMS_VALIDATE_CACHE_KEY => 'element-output-positional',
    );
        
    my ( $value, $slot, $name, $xmlns ) = validated_list(
        [@_[3..$#_]],
        value => { isa => 'Item', optional => 1 },
        slot => { isa => 'Int', optional => 1 },
        name => { isa => 'Str', optional => 1 },
        xmlns => { isa => 'Str', optional => 1 },
        MX_PARAMS_VALIDATE_CACHE_KEY => 'element-output-named',
    );
    
    
	$value //= do {
		my $accessor = $self->attrName;
		$item->$accessor;
	};
	if ( ref $value and ref $value eq "ARRAY" and defined $slot ) {
		$value = $value->[$slot];
	}
	$name //= do {
		if ( $self->has_nodeName_attr ) {
			my $attr = $self->nodeName_attr;
			$item->$attr;
		}
		else {
			$self->nodeName;
		}
	};
	$xmlns //= do {
		if ( $self->has_xmlns_attr ) {
			my $attr = $self->xmlns_attr;
			$item->$attr;
		}
		else {
			$self->xmlns // "";
		}
	};
	if ( ref $name ) {
		$name = $name->[$slot];
	}
	if ( ref $xmlns ) {
		$xmlns = $xmlns->[$slot];
	}

	my $nn;
	my $doc = $node->ownerDocument;
	my $newctx;
	if ( length $name ) {
		my ($prefix, $new_prefix);
		$ctx = $ctx->next_ctx( $xmlns, $name, $value );
		$prefix = $ctx->prefix;
		my $new_nodeName = ($prefix ? "$prefix:" : "") . $name;
		$nn = $doc->createElement($new_nodeName);
		if ( $ctx->prefix_new($prefix) ) {
			$nn->setAttribute(
				"xmlns".($prefix?":$prefix":""),
				$xmlns,
			);
		}
		$node->appendChild($nn);

		# now proceed with contents...
		if ( my $class = $self->nodeClass ) {
			my $m;
			if ( !defined $value ) {
				$ctx->exception("required element not set");
			}
			elsif ( eval { $value->isa($class) }) {
				$m = $ctx->base->get($class);
			}
			elsif ( eval{$value->isa("XML::LibXML::Element")} ) {
				if ($value->localname eq $nn->localname
					and
					($value->namespaceURI||"") eq
					($xmlns||"")
					)
				{   my $nn2 = $value->cloneNode(1);
					$node->appendChild($nn2);
					$node->removeChild($nn);
				}
				else {

					# it's just not safe to set
					# the nodeName after the fact,
					# so copy the children across.
					for my $att ( $value->attributes ) {
						next if $att->isa("XML::LibXML::Namespace");
						$nn->setAttribute(
							$att->localname,
							$att->value,
						);
					}
					for my $child ( $value->childNodes ) {
						my $nn2 = $child->cloneNode(1);
						$nn->appendChild($nn2);
					}
				}
				$m = "ok";
			}
			elsif ( blessed $value ) {

				# this actually indicates a type
				# error.  currently it is required for
				# the Whatever mapping.
				$m = PRANG::Marshaller->get(ref $value);
			}

			if ( $m and blessed $m ) {
				$ctx->exception(
					"tried to serialize unblessed value $value"
					)
					if !blessed $value;
				$m->to_libxml($value, $nn, $ctx);
			}
			elsif ($m) {

				# allow value-based code above to drop through
			}
			else {
				$ctx->exception("no marshaller for '$value'");
			}
		}
		elsif ( $self->has_contents and defined $value ) {
		    my $tn = $self->createTextNode($doc, $value);
			$nn->appendChild($tn);
		}
	}
	else {
	    $nn = $self->createTextNode($doc, $value);
		$node->appendChild($nn);
	}
}

with 'PRANG::Graph::Node';

1;

__END__

=head1 NAME

PRANG::Graph::Element - accept a particular type of element

=head1 SYNOPSIS

See L<PRANG::Graph::Meta::Element> source and
L<PRANG::Graph::Node> for examples and information.

=head1 DESCRIPTION

This graph node specifies that the XML graph at this point must accept
a particular type of element.

If the element only has only simple types (eg Str, Bool), it will not
have one of these objects in its graph.

Along with L<PRANG::Graph::Text>, this graph node is the only type
which may actually consume input XML nodes or emit them on output.
The other node types merely change the state in the
L<PRANG::Graph::Context> object.

=head1 ATTRIBUTES

=over

=item B<Str xmlns>

If set, then the XML namespace of this element is expected to be the
value passed (or absent).  This is generally not set if the namespace
of this portion of the graph is the same as the parent class.

=item B<nodeName>

This map is used for emitting and generating error messages.  Also, if
set to C<*> it has special meaning when parsing.  Specifies the name
of the node.

=item B<nodeName_attr>

If set, instances have an attribute which stores the name of the XML
element.

=item B<Str nodeClass>

This specifies the next type of element; during parsing and emitting,
recursion to the meta-object of this class occurs.

This will be undefined if the attribute has C<Bool> type; node
presence is true and absence is false.

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

