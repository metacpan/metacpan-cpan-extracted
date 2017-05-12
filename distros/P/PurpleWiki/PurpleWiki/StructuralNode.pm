# PurpleWiki::StructuralNode.pm
#
# $Id: StructuralNode.pm 352 2004-05-08 22:00:33Z cdent $
#
# Copyright (c) Blue Oxen Associates 2002-2003.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

package PurpleWiki::StructuralNode;

use 5.005;
use strict;
use PurpleWiki::InlineNode;

our $VERSION;
$VERSION = sprintf("%d", q$Id: StructuralNode.pm 352 2004-05-08 22:00:33Z cdent $ =~ /\s(\d+)\s/);

### constructor

sub new {
    my $this = shift;
    my (%options) = @_;
    my $self = {};

    # TODO: Type checking.
    $self->{type} = $options{type} ? $options{type} : undef;
    $self->{id} = $options{id} ? $options{id} : undef;
    $self->{content} = $options{content} ? $options{content} : undef;
    bless $self, $this;
    return $self;
}

### methods

sub insertChild {
    my $this = shift;
    my (%options) = @_;

    my $newNode = PurpleWiki::StructuralNode->new(%options);
    $newNode->{parent} = $this;
    push(@{$this->{children}}, $newNode);
    return $newNode;
}

sub parent {
    my $this = shift;
    return $this->{parent};
}

sub children {
    my $this = shift;

    return $this->{children};
}

### accessors/mutators

sub type {
    my $this = shift;

    $this->{type} = shift if @_;
    return $this->{type};
}

sub id {
    my $this = shift;

    $this->{id} = shift if @_;
    return $this->{id};
}

sub content {
    my $this = shift;

    $this->{content} = shift if @_;
    return $this->{content};
}

1;
__END__

=head1 NAME

PurpleWiki::StructuralNode - Structural node object

=head1 SYNOPSIS

  use PurpleWiki::InlineNode;
  use PurpleWiki::StructuralNode;

  # Create a 'section' node
  my $node = PurpleWiki::StructuralNode->new(type=>'section');

  # Insert a child node, and assign it to $currentNode
  my $currentNode = $node->insertChild;

  # Set current node's type to 'h'
  $currentNode->type('h');

  # Set node content to a new inline node of type 'text' and of
  # content 'Hello, world!'
  $currentNode->content(
      [PurpleWiki::InlineNode->new(type=>'text',
                                   content=>'Hello, world!')] );

  # The resulting tree is:
  # 
  # SECTION
  #    |
  #    +--- H: [TEXT: Hello, world!]
  #
  # where "[TEXT: Hello, world!]" refers to an inline node of type
  # 'text' and content 'Hello, world!'.

=head1 DESCRIPTION

Structural nodes are the main structural component of PurpleWiki
trees, representing document constructs such as sections, paragraphs,
and list items.  The basic data structure is:

  PurpleWiki::StructuralNode = {
    type     => document|section|h|p|pre|indent|ul|ol|li|dl|dt|dd
    id       => int
    content  => [PurpleWiki::InlineNode, ...]
    parent   => PurpleWiki::StructuralNode
    children => [PurpleWiki::StructuralNode, ...]
  }

The document, section, indent, ul, ol, and dl nodes types are
structural-only; their content field will always be undefined.  Only
the root node of a tree should be of type document.  The content field
is a reference to a list of inline nodes, and represents the content
of the structural node.

=head1 BNF CONSTRAINTS

PurpleWiki does not currently enforce constraints for structural node
types.  For example, you can create a section node with content, or a
p node with children, even though neither of those are technically
legal.

The BNF constraints for structural nodes are:

  document ::= section
  section ::= h|p|indent|ul|ol|dl|pre
  indent ::= p|indent
  ul ::= li|ul|ol|dl
  ol ::= li|ol|ul|dl
  dl ::= dt dd|dl|ul|ol

=head1 METHODS

=head2 new(%options)

Constructor.  Blesses hash with fields type, id, and content.  Values
for these fields may be passed as parameters via %options.

=head2 insertChild(%options)

Creates a new structural node and pushes it onto the current node's
list of children.  Returns the value of the new child node.  You can
set the child node's fields via the %options parameter, which will be
passed onto the constructor.

=head2 parent()

Returns the parent node.

=head2 children()

Returns the reference to the list of children.

=head2 Accessors/Mutators

 type()
 id()
 content()

=head1 AUTHORS

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Tree>, L<PurpleWiki::InlineNode>.

=cut
