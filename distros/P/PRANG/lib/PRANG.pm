
package PRANG;
$PRANG::VERSION = '0.18';
use strict;
use warnings;

our $EMIT_CDATA = 0;

1;

__END__

=encoding utf8

=head1 NAME

PRANG - XML graph engine - XML to Moose objects and back!

=head1 SYNOPSIS

 # step 1. define a common role for nodes in your XML language
 package XML::Language::Node;
 use Moose::Role;
 sub xmlns { "http://example.com/language/1.0" }

 # step 2. define the root node(s) of your language
 package XML::Language;
 use Moose;
 use PRANG::Graph;
 sub root_element {
     "envy"
 };
 has_attr 'laziness' =>
      is => "ro",
      isa => "Str",
      ;
 has_element 'lust' =>
      is => "ro",
      isa => "XML::Language::Lust",
      ;
 with 'PRANG::Graph', 'XML::Language::Node';

 # step 3. define further elements in your schema
 package XML::Language::Lust;
 use Moose;
 use PRANG::Graph;
 use PRANG::XMLSchema::Types;

 has_attr 'gluttony' =>
      is => "ro",
      isa => "PRANG::XMLSchema::byte",
      ;
 has_element 'sins' =>
      is => "ro",
      isa => "ArrayRef[XML::Language::Lust|Str]",
      xml_nodeName => {
          'lust' => 'XML::Language::Lust',
          'anger' => 'Str',
      },
      ;
 has_element 'greed' =>
      is => "ro",
      isa => "Bool",
      ;
 with 'XML::Language::Node';

 # step 4a.  parse!
 my $object = XML::Language->parse(<<XML);
 <envy laziness="Very">
   <lust gluttony="127">
     <anger>You wouldn't like me when I'm angry</anger>
     <lust>
       <anger>You've done it now!</anger>
       <greed />
     </lust>
   </lust>
 </envy>
 XML

 # Parsing the above would give you the same structure as this:
 XML::Language->new(
     laziness => "Very",
     lust => XML::Language::Lust->new(
         gluttony => 127,
         sins => [
             "You wouldn't like me when I'm angry",
             XML::Language::Lust->new(
                 sins => [ "You've done it now!" ],
                 greed => 1,
             ),
         ],
     )
 );

 # step 4b.  emit!
 $format = 1;
 print $object->to_xml($format);

=head1 DESCRIPTION

PRANG is an B<XML Graph> engine, which provides B<post-schema
validation objects> (PSVO).

It is designed for implementing XML languages for which a description
of the valid sets of XML documents is available - for example, a DTD,
W3C XML Schema or Relax specification.  With PRANG (and, like
L<XML::Toolkit>), your class structure I<is> your XML Graph.

XML namespaces are supported, and the module tries to make many XML
conventions as convenient as possible in the generated classes.  This
includes XML data (elements with no attributes and textnode contents),
and presence elements (empty elements with no attributes which
indicate something).  It also supports mixed and unprocessed portions
of the XML, and "pluggable" specifications.

Currently, these must be manually constructed as in the example -
details on this are to be found on the L<PRANG::Graph::Meta::Element>
and L<PRANG::Graph::Meta::Attr> perldoc.  There is also a cookbook of
examples - see L<PRANG::Cookbook>.

However, eventually it should be possible to automatically process
schema documents to produce a class structure (see L</KNOWN
LIMITATIONS>).

Once the L<PRANG::Graph> has been built, you can:

=over

=item B<marshall XML in>

The L<PRANG::Marshaller> takes any well-formed document parsable by
L<XML::LibXML>, and constructs a corresponding set of Moose objects.

A shortcut is available via the C<parse> method on the starting point
of the graph (indicated by using the role 'L<PRANG::Graph>').

You can also parse documents which have multiple start nodes, by
defining a role which the concrete instances use.

eg, for the example in the SYNOPSIS; define a role
'XML::Language::Family' - the root node will be parsed by the class
with a matching C<root_element> (and C<xmlns>) value.

 package XML::Language::Family;
 use Moose::Role;
 with 'PRANG::Graph';

 package XML::Language;
 use Moose;
 with 'XML::Language::Family';

 # later ...
 my $marshaller = PRANG::Marshaller->get("XML::Language::Family");
 my $object = $marshaller->parse($xml);

B<note> the C<PRANG::Marshaller> API will probably go away in a future
release, once the "parse" role method is made to work correctly.

=item B<marshall XML out>

A L<PRANG::Graph> structure also has a C<to_xml> method, which emits
XML (optionally indented).

=back

=head1 Global Options

There are some (well, one at the moment) global options which can be
set via:

$PRANG::OPTION = 'value';

=item B<EMIT_CDATA>

Setting this to true will emit all text nodes as CDATA elements rather
than just text. Default is false.

Note, for parsing, CDATA and text are treated as the same.

=back

=head1 Why "XML Graph"?

The term B<XML Graph> is from the paper, "XML Graphs in Program
Analysis", Møller and Schwartzbach (2007).

L<http://www.brics.dk/~amoeller/papers/xmlgraphs/>

The difference between an B<Graph> and a B<Tree>, is that a Graph can
contain cycles, whereas a Tree cannot - there is only one correct way
to follow a tree, whereas there can be many correct ways to follow a
graph.

So, XML documents are considered to be trees, and the mechanisms which
describe allowable forms for those trees XML graphs.

They are graphs, because they can contain cycles - cycles in an XML
graph might point back to the same element (indicating an "any number
of this element" condition), or point to a different element closer to
the initial element (indicating an arbitrary level of nesting).

=head1 KNOWN LIMITATIONS

Support for these features will be considered as tuits allow.  If you
can create a patch for any of these features which meets the coding
standards, they are very likely to be accepted.  The authors will
provide guidance and/or assistance through this process, time and
patience permitting.

=head2 Creating XML Graphs from Schema documents

Validating/Parsing schema documents, and transforming those
to a L<PRANG::Graph> structure, could well be a valid approach to
address these issues and may be addressed by later releases and/or
modules which implement those XML languages using PRANG.

=head2 Creating XML Graphs from example documents

This is a bit more shonky an approach, but can be very useful for
I<ad-hoc> XML conventions for which no rigid definition can be found.
Currently, L<XML::Toolkit> is the best module for this.

=head2 Validating Indeterminate Graphs

It's possible that at a given point in time, a graph may be followed
in more than one direction, and the correct direction cannot be
determined based on the currently input token.  However, few if any
XML languages are this indeterminate, so while many schema languages
may allow this to be specified, they should (hopefully) not correspond
to major standards.

=head1 SOURCE, SUBMISSIONS, SUPPORT

Source code is available from Catalyst:

  git://git.catalyst.net.nz/PRANG.git

And Github:

  git://github.com/catalyst/PRANG.git

Please see the file F<SubmittingPatches> for information on preferred
submission format.

Suggested avenues for support:

=over

=item *

Moose user's mailing list - see the L<Moose> perldoc for more
information.  Please check with the latest release of PRANG - if there
is sufficient interest, a separate list may have been created.

=item *

Contact the author and ask either politely or commercially for help.

=item *

Log a ticket on L<http://rt.cpan.org/>

=back

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut
