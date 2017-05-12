
package PRANG::Graph;
$PRANG::Graph::VERSION = '0.18';
use Moose::Role;
use Moose::Meta::TypeConstraint;

use PRANG;
use PRANG::Graph::Context;

use PRANG::Graph::Node;
use PRANG::Graph::Element;
use PRANG::Graph::Text;
use PRANG::Graph::Seq;
use PRANG::Graph::Choice;
use PRANG::Graph::Quantity;

use PRANG::Graph::Meta::Attr;
use PRANG::Graph::Meta::Element;
use MooseX::Params::Validate;

use PRANG::Marshaller;

use Moose::Exporter;

sub has_attr {
	my ( $meta, $name, %options ) = @_;
	my $traits_a = $options{traits} ||= [];
	push @$traits_a, "PRANG::Attr";
	$meta->add_attribute(
		$name,
		%options,
	);
}

sub has_element {
	my ( $meta, $name, %options ) = @_;
	my $traits_a = $options{traits} ||= [];
	push @$traits_a, "PRANG::Element";
	$meta->add_attribute(
		$name,
		%options,
	);
}

Moose::Exporter->setup_import_methods(
	with_meta => [qw(has_attr has_element)],
	class_metaroles => {
	    class => [qw(PRANG::Graph::Meta::Class)],
	},
);


requires 'xmlns';
requires 'root_element';

sub marshaller { #returns PRANG::Marshaller {
    my $inv = shift;
    
	if ( ref $inv ) {
		$inv = ref $inv;
	}
	PRANG::Marshaller->get($inv);
}

sub parse {
    my $class = shift;
    
    my ( $xml, $lax ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'Bool', optional => 1, default => 0 }, 
    );

	my $instance = $class->marshaller->parse( xml => $xml, lax => $lax );
	return $instance;
}

sub parse_file {
    my $class = shift;
    my ( $filename, $lax ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'Bool', optional => 1, default => 0 }, 
    );    
    
	my $instance = $class->marshaller->parse( filename => $filename, lax => $lax  );
	return $instance;
}

sub parse_fh() {
    my $class = shift;
    my ( $fh, $lax ) = pos_validated_list(
        \@_,
        { isa => 'GlobRef' },
        { isa => 'Bool', optional => 1, default => 0 }, 
    );        
    
	my $instance = $class->marshaller->parse( fh => $fh, lax => $lax  );
	return $instance;
}

sub from_dom {
    my $class = shift;
    my ( $dom, $lax ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Document' },
        { isa => 'Bool', optional => 1, default => 0 },
    );

    my $instance = $class->marshaller->from_dom( dom => $dom, lax => $lax  );
    return $instance;
}

sub from_root_node {
    my $class = shift;
    my ( $root_node, $lax ) = pos_validated_list(
        \@_,
        { isa => 'XML::LibXML::Node' },
        { isa => 'Bool', optional => 1, default => 0 },
    );

    my $instance = $class->marshaller->from_root_node( root_node => $root_node, lax => $lax  );
    return $instance;
}

sub to_xml() {
    my $self = shift;
    my ( $format ) = pos_validated_list(
        \@_,
        { isa => 'Int', default => 0 },
    );          
    
	my $marshaller = $self->marshaller;
	$marshaller->to_xml( $self, $format );
}

1;

=head1 NAME

PRANG::Graph - XML mapping by peppering Moose attributes

=head1 SYNOPSIS

 # declaring a /language/
 package My::XML::Language;
 use Moose;
 use PRANG::Graph;
 sub xmlns { "some:urn" }
 sub root_element { "Root" }
 with 'PRANG::Graph';
 has_element "data" =>
     is => "ro",
     isa => "My::XML::Language::Node",
     ;

 # declaring a /node/ in a language
 package My::XML::Language::Node;
 use Moose;
 use PRANG::Graph;
 has_attr "count" =>
     is => "ro",
     isa => "Num",
     ;
 has_element "text" =>
     is => "ro",
     isa => "Str",
     xml_nodeName => "",
     ;

 package main;
 # example document for the above.
 my $xml = q[<Root xmlns="some:urn"><data count="2">blah</data></Root>];

 # loading XML to data structures
 my $parsed = My::XML::Language->parse($xml);

 # alternatives
 $parsed = My::XML::Language->parse_file($filename);
 $parsed = My::XML::Language->parse_fh($fh);
 $parsed = My::XML::Language->from_dom($dom); # $dom isa XML::LibXML::Document

 # converting back to XML
 print $parsed->to_xml;

=head1 DESCRIPTION

PRANG::Graph allows you to mark attributes on your L<Moose> classes as
corresponding to XML attributes and child elements.  This allows your
class structure to function as an I<XML graph> (a generalized form of
an specification for the shape of an XML document; ie, what nodes and
attributes are allowed at which point).

=head2 PRANG::Graph for document types

If a class implements a document type, that is, it is a valid root
node for your language, it B<must> both C<use> and implement the
C<PRANG::Graph> role, and implement the required functions C<xmlns>
and C<root_element>;

  package XML::Language;
  use Moose;
  use PRANG::Graph;
  sub xmlns { }
  sub root_element { "rootNode" }
  with 'PRANG::Graph';

If no URL is returned by the C<xmlns> function, XML namespaces are not
permitted in the input documents.

=head2 PRANG::Graph for element types

If a class implements an element, that is, a node which appears
somewhere other than the root node of your language, it B<must> C<use>
the C<PRANG::Graph> package.  Well, actually, it must apply the PRANG
class trait, but using the package will also define the useful
functions C<has_attr> and C<has_element>, so most users will want
that.

The minimum is;

 package XML::Language::SomeElement;
 use PRANG::Graph;

Note, the name of the node is not defined in the class itself, it is
defined in the class which includes it, using the C<has_element>
method.  See L<PRANG::Graph::Meta::Element> for more information.

=head2 PRANG::Graph for multi-root document types

If your language has multiple valid root elements, then you must
define one document type for each valid root element.  These must all
implement a particular role, which should bundle the C<PRANG::Graph>
role.  The common role should not define C<root_element>, but probably
should define C<xmlns> in most cases:

eg,

  package XML::Language::Family;
  use Moose::Role;
  sub xmlns { }
  with 'PRANG::Graph';

  package XML::Language::One;
  use Moose;
  use PRANG::Graph;
  sub root_element { "one" }
  with 'XML::Language::Family';

  package XML::Language::Two;
  use Moose;
  use PRANG::Graph;
  sub root_element { "two" }
  with 'XML::Language::Family';

=head2 PRANG::Graph for plug-in element types

Normally, the details on the node name of elements is in the class
which includes those elements, not the target classes.  However, it is
also possible to refer to roles instead of classes.  The first time
the parser encounters this, it sees which loaded classes implement
that role, and then builds the map from element name to class.

The classes should implement the C<PRANG::Graph> role, effectively
defining a document type.

The effect of specifying a role as a type is to immediate search all
I<loaded packages> to see which consume the specified role.

Given the example in the previous section, if you used:

 has_element 'some_attr' =>
     is => "ro",
     isa => "XML::Language::Family",
     ;

It would be the same as:

 has_element 'some_attr' =>
     is => "ro",
     isa => "XML::Language::One|XML::Language::Two",
     xml_nodeName => {
         one => "XML::Language::One",
         two => "XML::Language::Two",
     },
     ;

Otherwise, the requirements are the same as for regular element
definition as described in L<PRANG::Graph::Meta::Element>.  In
particular, two types cannot share the same C<xmlns> I<and>
C<root_element>; that would be ambiguous.

=head1 EXPORTS

These exports are delivered to the class which says C<use
PRANG::Graph;>

=head2 has_attr

This is the same as declaring an attribute using the regular Moose
C<has> keyword, but adds the C<PRANG::Attr> trait, declared in
L<PRANG::Graph::Meta::Attr> - the attribute will behave just like a
regular Moose attribute, but the marshalling machinery will convert it
to and from a particular XML attribute (or even multiple attributes).
See L<PRANG::Graph::Meta::Attr> for more information.

=head2 has_element

Same as C<has_attr>, except it adds the C<PRANG::Element> trait,
indicating to the marshalling machinery to emit an XML node or
sequence of nodes.  See L<PRANG::Graph::Meta::Element>.

=head1 METHODS

These methods are defined in, or required classes which implement the
C<PRANG::Graph> I<role>.  In general, that means they are a document
type.

=head2 B<parse($class: Str $xml, Bool $lax) returns Object>

Parse an XML string according to the PRANG Graph and return the built
object.  Throws exceptions on error.

By example, this is:

 my $object = $class->parse($xml);
 
The $lax param tells PRANG to use 'lax' parsing mode. This ignores
any extra elements or attributes in the XML that haven't been
specified in your definition classes. This is useful if you're
parsing XML from a trusted source, but that source may introduce
new elements and attributes. Using lax mode, your parser will
be forwards compatible for any additions. 

Without lax mode, any attributes or elements not defined in your
classes will cause PRANG to throw an exception.

=head2 B<to_xml(PRANG::Graph $object: Int $format = 0) returns Str>

Converts an object to an XML string.  The returned XML will include
the XML declaration and so on.
Output will be indented by LibXML2 if the C<format> parameter is set
to 1.  The default is 0 (do not indent).  See
L<XML::LibXML::Document/toString> for other valid values.

By example, this is:

 my $xml = $object->to_xml;

=head2 B<xmlns(Moose::Meta::Class $class:) returns Maybe[Str]>

This is a B<required class method> which returns the XML namespace of
this document type.  This is used for emitting, and when parsing the
input namespace must generally be either unset or match this XML
namespace.

If you are not using namespaces, just define the method in your class,
and return a false value.

=head2 B<encoding() returns Maybe[Str]>

Class method that defines the encoding for this class when emitting XML. 
Defaults to 'UTF-8'.

=head2 B<root_element(Moose::Meta::Class $class:) returns Str>

This is a B<required class method> which returns the XML name of the
element which corresponds to this document type.

=head1 HOW IT WORKS

These details are not important for regular use of PRANG, however if
you can understand this you will grok the module much more quickly.

This class applies a I<trait> to your classes' metaclass.  This means,
that when you C<use PRANG::Graph>, there is an implied;

  use Moose -traits => ["PRANG"];

Which is something like;

  PRANG::Graph::Meta::Class->meta->apply(__PACKAGE__->meta);

That sets up the metaclass to be capable of being used by the
marshalling machinery.  This machinery expects Moose attributes which
have the C<PRANG::Element> or C<PRANG::Attr> traits applied to connect
XML attributes and elements to object attributes.  These are in turn
implemented by the L<PRANG::Graph::Meta::Attr> and
L<PRANG::Graph::Meta::Element> classes.

Applying the L<PRANG::Graph> role happens separately, and delivers a
separate set of super-powers.  It is roughly equivalent to;

  PRANG::Graph->meta->apply(__PACKAGE__);

So, the key difference between these two aspects are the source
package, and the destination meta-object; in one, it is the class, in
the other, the metaclass.

=head1 SEE ALSO

L<PRANG>, L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Attr>,
L<PRANG::Graph::Meta::Element>, L<PRANG::Graph::Node>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

