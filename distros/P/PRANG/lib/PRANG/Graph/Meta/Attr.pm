
package PRANG::Graph::Meta::Attr;
$PRANG::Graph::Meta::Attr::VERSION = '0.18';
use Moose::Role;

has 'xmlns' =>
	is => "rw",
	isa => "Str",
	predicate => "has_xmlns",
	;

has 'xml_isa' =>
	is => "rw",
	isa => "Str|Moose::Meta::TypeConstraint",
	predicate => "has_xml_isa",
	;

has 'xml_name' =>
	is => "rw",
	isa => "Str",
	predicate => "has_xml_name",
	;

has 'xml_required' =>
	is => "rw",
	isa => "Bool",
	predicate => "has_xml_required",
	;

has 'xmlns_attr' =>
	is => "rw",
	isa => "Str",
	predicate => "has_xmlns_attr",
	;

package Moose::Meta::Attribute::Custom::Trait::PRANG::Attr;
$Moose::Meta::Attribute::Custom::Trait::PRANG::Attr::VERSION = '0.18';
sub register_implementation {
	"PRANG::Graph::Meta::Attr";
}

1;

=head1 NAME

PRANG::Graph::Meta::Attr - metaclass metarole for XML attributes

=head1 SYNOPSIS

 package My::XML::Language::Node;

 use Moose;
 use PRANG::Graph;

 has_attr 'someattr' =>
    is => "rw",
    isa => $str_subtype,
    predicate => "has_someattr",
    ;

=head1 DESCRIPTION

When defining a class, you mark attributes which correspond to XML
attributes.  To do this in a way that the PRANG marshalling machinery
can use when converting to XML and back, make the attributes have this
metaclass.

You could do this in principle with:

 has 'someattr' =>
    traits => ['PRANG::Attr'],
    ...

But L<PRANG::Graph> exports a convenient shorthand for you to use.

If you like, you can also set the C<xmlns> and C<xml_name> attribute
property, to override the default behaviour, which is to assume that
the XML attribute name matches the Moose attribute name, and that the
XML namespace of the attribute is empty.  Note if you specify the
C<xmlns> for an attribute, it I<must> have that namespace set, or it
is not the same attribute.

If you set the C<xml_required> property, then it is an error for the
property not to be set when parsing or emitting.

Setting the C<xmlns> attribute to C<*> will allow any XML namespace to
be set for that attribute.  In this case, you should also set the
C<xmlns_attr> property, which should refer to another attribute which
will record which XML namespace URI was passed in.  This introduces a
potential ambiguity; the same attribute may be passed in multiple
times, with different XML namespaces.

You can also set C<xml_isa>, which currently if set will not check the
type constraint against the input on marshall in.  In the future it
will specify the type constraint to apply at marshall in time, instead
of waiting for the constructor to apply one.

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Element>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut
