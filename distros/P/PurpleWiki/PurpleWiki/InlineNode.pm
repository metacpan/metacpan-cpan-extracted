# PurpleWiki::InlineNode.pm
#
# $Id: InlineNode.pm 352 2004-05-08 22:00:33Z cdent $
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

package PurpleWiki::InlineNode;

use 5.005;
use strict;

our $VERSION;
$VERSION = sprintf("%d", q$Id: InlineNode.pm 352 2004-05-08 22:00:33Z cdent $ =~ /\s(\d+)\s/);

### constructor

sub new {
    my $this = shift;
    my (%options) = @_;
    my $self = {};

    # TODO: Type checking.
    $self->{type} = $options{type} ? $options{type} : undef;
    $self->{href} = $options{href} ? $options{href} : undef;
    $self->{class} = $options{class} ? $options{class} : undef;
    $self->{content} = $options{content} ? $options{content} : undef;
    $self->{children} = $options{children} ? $options{children} : undef;
    bless $self, $this;
    return $self;
}

### accessors/mutators

sub type {
    my $this = shift;

    $this->{type} = shift if @_;
    return $this->{type};
}

sub href {
    my $this = shift;

    $this->{href} = shift if @_;
    return $this->{href};
}

sub class {
    my $this = shift;

    $this->{class} = shift if @_;
    return $this->{class};
}

sub content {
    my $this = shift;

    $this->{content} = shift if @_;
    return $this->{content};
}

sub children {
    my $this = shift;

    $this->{children} = shift if @_;
    return $this->{children};
}

1;
__END__

=head1 NAME

PurpleWiki::InlineNode - Inline node object

=head1 SYNOPSIS

  use PurpleWiki::InlineNode;

  # Create node of type 'text' and content 'Hello, world!'
  my $inlineNode1 =
      PurpleWiki::InlineNode->new(type => 'text',
                                  content => 'Hello, world!');

  # Represent bolded and italicized 'Hello, world!'.
  # First, create node of type 'b'.
  my $boldNode = PurpleWiki::InlineNode->new(type => 'b');

  # Create node of type 'i'.
  my $italicsNode = PurpleWiki::InlineNode->new(type => 'i');

  # Create 'text' node with content 'Hello, world!'.
  my $textNode =
      PurpleWiki::InlineNode->new(type => 'text',
                                  content => 'Hello, world!');

  # Make 'text' node a child of 'i' node, and 'i' node a child
  # of 'b' node.
  $italicsNode->children([$textNode]);
  $boldNode->children([$italicsNode]);

=head1 DESCRIPTION

Inline nodes make up the content of structural nodes.  They are mostly
content containers, although some types use children to handle nested
inline content, such as bold and italicized content.

The data structure looks like:

  PurpleWiki::InlineNode = {
    type     => text|nowiki|b|i|tt|wikiword|freelink|link|url|image
    href     => string
    content  => string
    children => [PurpleWiki::InlineNode, ...]
  }

=head2 Content Nodes

There are two content nodes: text and nowiki.  Both use the content
field, and neither allow nesting.

The nowiki type is useful for serializing trees as WikiText.  For
example, if you had the text:

  Brevity is the soul of wit. --WilliamShakespeare

it would make no difference to PurpleWiki internally if you treated
this as either a text node or a nowiki node.  In both cases,
"WilliamShakespeare" is not treated as a Wiki word.  However, the
correct WikiText serialization is:

  <nowiki>Brevity is the soul of wit.  --WilliamShakespeare</nowiki>

Without the nowiki tags, WilliamShakespeare looks like a node of type
'wikiword', which is not the case in this example.  If we did not have
a nowiki type, then the View driver would have to parse the contents
of the text node to see if anything ought to be surrounded by nowiki
tags.

=head2 Nested Nodes

There are three types of nested nodes: b, i, and tt.  The BNF
constraints are as follows:

  b ::= text|nowiki|i|tt|wikiword|freelink|link|url|image
  i ::= text|nowiki|b|tt|wikiword|freelink|link|url|image
  tt ::= text|nowiki|b|i|wikiword|freelink|link|url|image

The content field of these types of nodes should be left undefined.

Suppose you had a paragraph consisting of an italicized sentence with
a fixed font word:

  <i>Hello, <tt>world!</tt></i>

The corresponding inline nodes would be:

  I
  |
  +-- TEXT: 'Hello, '
  |
  +-- TT
       |
       +-- TEXT: 'world!'

In other words, you would have an i node with two children: a text
node with content 'Hello, ', and a tt node.  The tt node would have
one child: a text node with content 'world!'.

=head2 Link Nodes

There are four types of link nodes:

  wikiword -- WikiWord
  freelink -- free link (double bracketed links)
  link     -- links (bracketed links)
  url      -- URLs
  image    -- images

Each of these nodes use both the content and href fields.  Link nodes
are not nested.

=head1 AUTHORS

Chris Dent, E<lt>cdent@blueoxen.orgE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::StructuralNode>.

=cut
