
# Here is the offending definition for this:

#  <complexType name="mixedMsgType" mixed="true">
#    <sequence>
#      <any processContents="skip"
#       minOccurs="0" maxOccurs="unbounded"/>
#    </sequence>
#    <attribute name="lang" type="language"
#     default="en"/>
#  </complexType>

# The mixed="true" part means that we can have character data (the
# validation of which cannot be specified AFAIK).  See
#  http://www.w3.org/TR/xmlschema11-1/#Complex_Type_Definition_details
#
# Then we get an unbounded "any", with processContents="skip"; this
# means that everything under this point - including XML namespace
# definitions, etc - should be completely ignored.  The only
# requirement is that the contents are valid XML.  See
#  http://www.w3.org/TR/xmlschema11-1/#Wildcard_details

# XXX - should really make roles for these different conditions:

#    PRANG::XMLSchema::Wildcard::Skip;
#
#      'skip' specifically means that no validation is required; if
#      the input document specifies a schema etc, that information is
#      to be ignored.  In this instance, we may as well be returning
#      the raw LibXML nodes.

#    PRANG::XMLSchema::Wildcard::Lax;
#
#      processContents="lax" means to validate if the appropriate xsi:
#      etc attributes are present; otherwise to treat as if it were
#      'skip'

#    PRANG::XMLSchema::Wildcard::Strict;

#      Actually this one may not be required; just specifying the
#      'Node' role should be enough.  As 'Node' is not a concrete
#      type, the rest of the namespace and validation mechanism should
#      be able to check that the nodes are valid.

# In addition to these different classifications of the <any>
# wildcard, the enclosing complexType may specify mixed="true";
# so, potentially there are two more roles;

#    PRANG::XMLSchema::Any;              (cannot mix data and elements)
#    PRANG::XMLSchema::Any::Mixed;       (can mix them)

# however dealing with all of these different conditions is currently
# probably premature; the schema we have only contains 'strict' (which
# as noted above potentially needs no explicit support other than
# correct XMLNS / XSI implementation) and 'Mixed' + 'Skip'; so I'll
# make this "Whatever" class to represent this most lax of lax
# specifications.

package PRANG::XMLSchema::Whatever;
$PRANG::XMLSchema::Whatever::VERSION = '0.18';
use Moose;
use MooseX::Params::Validate;
use PRANG::Graph;

has_element 'contents' =>
	is => "rw",
	isa => "ArrayRef[PRANG::XMLSchema::Whatever|Str]",
	xml_nodeName =>
	{ "" => "Str", "*" => "PRANG::XMLSchema::Whatever" },
	xml_nodeName_attr => "nodenames",
	xmlns => "*",
	xmlns_attr => "nodenames_ns",
	xml_min => 0,
	;

has 'nodenames' =>
	is => "rw",
	isa => "ArrayRef[Maybe[Str]]",
	;

has 'nodenames_ns' =>
	is => "rw",
	isa => "ArrayRef[Maybe[Str]]",
	;

has_attr 'attributes' =>
	is => "rw",
	isa => "HashRef[Str|ArrayRef[Str]]",
	xmlns => "*",
	xml_name => "*",
	xmlns_attr => "attributes_ns",
	predicate => 'has_attributes',
	;

has 'attributes_ns' =>
	is => "rw",
	isa => "HashRef[Str|ArrayRef[Str]]",
	;

1;

=head1 NAME

PRANG::XMLSchema::Whatever - node type for nested anything

=head1 SYNOPSIS

 package My::XML::Element::Type;
 use Moose;
 use PRANG::Graph;

 has 'error_fragment' =>
    is => "rw",
    isa => "PRANG::XMLSchema::Whatever",
    ;

=head1 DESCRIPTION

Some schema allow sections of responses to be schema-free; typically
this is used for error responses which are allowed to include the
errant section of XML.

Fortunately, PRANG is flexible enough that this is quite easy to do.
The result of the operation is a nested set of
PRANG::XMLSchema::Whatever objects, which have two properties
C<contents> and C<attributes>, which store the sub-elements and
attributes of the element at that point.  There is also the attribute
C<nodenames> which stores the node names of nodes.  Once it is
supported, there will also be an attribute indicating the XML
namespaces of attributes and elements (currently they will not
round-trip successfully).

This API is somewhat experimental, and may be broken down into various
versions of 'whatever' - see the source for more.

=head1 SEE ALSO

L<PRANG>, L<PRANG::Graph::Meta::Attr>, L<PRANG::Graph::Meta::Element>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

