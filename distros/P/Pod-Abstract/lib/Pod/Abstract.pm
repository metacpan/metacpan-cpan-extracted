package Pod::Abstract;
use strict;
use warnings;

use Pod::Abstract::Node;
use Pod::Abstract::Path;
use Pod::Abstract::Parser;
use IO::String;

our $VERSION = '0.26';

=head1 NAME

Pod::Abstract - Abstract document tree for Perl POD documents

=head1 SYNOPSIS

 use Pod::Abstract;
 use Pod::Abstract::BuildNode qw(node);

 # Get all the first level headings, and put them in a verbatim block
 # at the start of the document
 my $pa = Pod::Abstract->load_filehandle(\*STDIN);
 my @headings = $pa->select('/head1@heading');
 my @headings_text = map { $_->pod } @headings;
 my $headings_node = node->verbatim(join "\n",@headings_text);

 $pa->unshift( node->cut );
 $pa->unshift( $headings_node );
 $pa->unshift( node->pod );

 print $pa->pod;

=head1 DESCRIPTION

C<Pod::Abstract> provides a means to load a POD document without direct
reference to it's syntax, and perform manipulations on the abstract
syntax tree.

This can be used to support additional features for POD, to format
output, to compile into alternative formats, etc.

POD documents are not a natural tree, but do have a logical nesting
structure. C<Pod::Abstract> makes this explicit - C<=head*> commands
create nested sections, =over and =back create nested lists, etc.

The "paf summary" command provides easy visualisation of the created
tree.

=head2 USAGE

C<Pod::Abstract> allows easy manupulation and traversal of POD or Perl
files containing POD, without having to manually do any string
manipulation.

It allows you to easily write formatters, filters, test scripts, etc
for POD.

C<Pod::Abstract> is based on the standard L<Pod::Parser> module.

=head2 PROCESSING MODEL

C<Pod::Abstract> allows documents to be loaded, decorated, and
manupulated in multiple steps. It can also make generating a POD
formatter very simple. You can easily add features to an existing POD
formatter, since any POD abstract object can be written out as a POD
document.

Rather than write or fork a whole translator, a single inline
"decorator" can be added.

The C<paf> utility provides a good starting point, which also allows
you to hook in to an existing filter/transform library. Add a
C<Pod::Abstract::Filter> class to the namespace and it should start
working as a C<paf> command.

=head2 EXAMPLE

Suppose you are frustrated by the verbose list syntax used by regular
POD. You might reasonably want to define a simplified list format for
your own use, except POD formatters won't support it.

With Pod::Abstract you can write an inline filter to convert:

 * item 1
 * item 2
 * item 3

into:

 =over

 =item *

 item 1

 =item *

 item 2

 =item *

 item 3

 =back

This transformation can be performed on the document tree. If your
formatter does not use Pod::Abstract, you can pipe out POD and use a
regular formatter. If your formatter supports Pod::Abstract, you can
feed in the syntax tree without having to re-serialise and parse the
document.

The source document is still valid Pod, you aren't breaking
compatibility with regular perldoc just by making Pod::Abstract
transformations.

=head2 POD SUPPORT

C<Pod::Abstract> supports all POD rules defined in perlpodspec.

=head1 COMPONENTS

Pod::Abstract is comprised of:

=over

=item *

The parser, which loads a document tree.

e.g:

 my $pa = Pod::Abstract->load_filehandle(\*STDIN);

=item *

The document tree, returned from the parser. The root node (C<$pa>
above) represents the whole document. Calling B<< ->pod >> on the root node
will give you back your original document.

Note the document includes C<#cut> nodes, which are generally the Perl
code - the parts that aren't POD. These will be included in the output
of B<< ->pod >> unless you remove them, so you can modify a Perl module
as a POD document in POD abstract, and it will work the same
afterwards.

e.g

 my $pod_text = $pa->pod; # $pod_text is reserialized from the tree.

See L<Pod::Abstract::Node>

=item *

L<Pod::Abstract::Path>, a node selection language. Called via C<<
$node->select(PATH_EXP) >>. Pod paths are a powerful feature allowing
declarative traversal of a document.

For example -

"Find all head2s under METHODS"

 /head1[@heading=~{^METHODS$}]/head2

"Find all bold text anywhere"

 //B

=item *

The node builder, L<Pod::Abstract::BuildNode>. This exports methods to
allow adding content to POD documents.

You can also combine documents - 

 use Pod::Abstract::BuildNode qw(node nodes);
 # ...
 my @nodes = nodes->from_pod($pod);

Where C<$pod> is a text with POD formatting.

=back

=head2 Using paths

The easiest way to traverse a C<$pa> tree is to use the C<select> method on the
nodes, and paths.

C<select> will accept and expression and return an array of
L<Pod::Abstract::Node>. These nodes also support the select method - for example:

 my @headings = $pa->select('/head1'); # Get all heading 1
 my @X = $headings[0]->select('//:X'); # Get all X (index) sequences inside that heading
 my @indices = map { $_->text } @X; # Map out the contents of those as plain text.

You can combine path expressions with other methods, for example - C<children>
will give all the child nodes of a POD node, C<next>, C<previous>, C<parent> and
C<root> allow traversal from a given node.

From any node you can then call C<select> to make a declarative traversal from
there. The above methods also have comparable expressions in
L<Pod::Abstract::Path>.

=head2 Traversing for document generation

To traverse the tree for document generation, you can follow C<children> from
the first node, then examine each node type to determine what you should
generate.

The nodes will generate in a tree, so headings have nested children with
subheadings and texts. In most cases the C<body> method will give the text (or
POD nodes) next to the command, while the C<children> method will give the
contained POD.

Special types are C<:paragraph>, C<:text>, <#cut>. Interior sequences are also
started with a : for their type, like C<:L>, C<:B>, C<:I> for Link, Bold,
Italic.

Use the C<< $node->ptree >> method to see a visualised tree of a parsed document.

=head1 METHODS

=cut


=head2 load_file

 my $pa = Pod::Abstract->load_file( FILENAME );

Read the POD document in the named file. Returns the root node of the
document.

=cut

sub load_file {
    my $class = shift;
    my $filename = shift;
    
    my $p = Pod::Abstract::Parser->new;
    $p->parse_from_file($filename);
    $p->root->coalesce_body(":verbatim");
    $p->root->coalesce_body(":text");

    # Remove any blank verbatim nodes.
    $_->detach foreach $p->root->select('//:verbatim[ . =~ {^[\s]*$}]');
    return $p->root;
}

=head2 load_filehandle

 my $pa = Pod::Abstract->load_file( FH );

Load a POD document from the provided filehandle reference. Returns
the root node of the document.

=cut

sub load_filehandle {
    my $class = shift;
    my $fh = shift;

    my $p = Pod::Abstract::Parser->new;
    $p->parse_from_filehandle($fh);
    $p->root->coalesce_body(":verbatim");
    $p->root->coalesce_body(":text");

    # Remove blank verbatim nodes.
    $_->detach foreach $p->root->select('//:verbatim[ . =~ {^[\s]*$}]');
    return $p->root;
}

=head2 load_string

 my $pa = Pod::Abstract->load_string( STRING );

Loads a POD document from a scalar string value. Returns the root node
of the document.

=cut

sub load_string {
    my $class = shift;
    my $str = shift;
    
    my $fh = IO::String->new($str);
    return $class->load_filehandle($fh);
}

=head1 AUTHOR

Ben Lilburne <bnej80@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2025 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
