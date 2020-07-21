package Net::IPAM::Tree::Node;

use 5.10.0;
use strict;
use warnings;
use List::MoreUtils qw();

=head1 NAME

Net::IPAM::Tree::Node - A node in the Net::IPAM::Tree

=head1 SYNOPSIS

This module is not useful standalone, it's just needed for Net::IPAM::Tree

A node is a recursive datastructure with a payload (block) and a parent and zero or more child nodes.

  node = {
    block  => Net::IPAM::Block,
    parent => Net::IPAM::Tree::Node,
    childs => [ Net::IPAM::Tree::Node, ... ],
  };

  use Net::IPAM::Tree::Node;

  my $n = Net::IPAM::Tree::Node->new( { block => $block, parent = $node, childs = [] } );

=head1 METHODS

=head2 new

Create Net::IPAM::Tree::Node object.

=cut

sub new {
  return bless $_[1], $_[0];
}

=head2 block

Accessor for the block attribute.

  print $node->block;

=cut

sub block {
  return $_[0]->{block};
}

=head2 parent

Accessor for the parent attribute.

  $parent = $node->parent

=cut

sub parent {
  return $_[0]->{parent};
}

=head2 childs

Accessor for the childs attribute.

  $child = $node->childs->[$i]

=cut

sub childs {
  return @{ $_[0]->{childs} };
}

####
# _insert_node($block)
#
# One method for inserting new nodes and parent-child relinking, recursive descent, heavy duty,
# key algorithm for this tree.
#
# Returns undef on duplicate block.
#

sub _insert_node {
  my ( $node, $input ) = @_;

  # number of childs
  my $nc = scalar @{ $node->{childs} };

  # childs are sorted find pos in childs on this level
  # find first index where child->{block} >= input->{block}
  # -1 if $node->{childs} is an empty array
  my $idx = List::MoreUtils::lower_bound { $_->{block}->cmp( $input->{block} ) } @{ $node->{childs} };

  # idx not -1 and not at end of slice, check for dup block
  if ( $idx >= 0 && $idx < $nc && $input->{block}->cmp( $node->{childs}[$idx]->{block} ) == 0 ) {

    # don't insert dups, return undef, must be handled at callers side
    return;
  }

  # not in front of slice, check if prev child contains this new node
  if ( $idx > 0 ) {
    my $prev = $node->{childs}[ $idx - 1 ];
    if ( $prev->{block}->contains( $input->{block} ) ) {

      # it's contained, recursive descent, return success or undef on failure
      return $prev->_insert_node($input);
    }
  }

  # add as new child on this level
  # set parent to this current node
  $input->{parent} = $node;

  # childs are empty, just append
  if ( $idx < 0 ) {
    push @{ $node->{childs} }, $input;
    return 1;
  }

  # input is greater than all others and not contained in any child before, just append
  if ( $idx == $nc ) {
    push @{ $node->{childs} }, $input;
    return 1;
  }

  # ###
  # input new node somewhere in the 'middle', insert in place, complex algo due to relinking
  # $node->{childs} = [..$idx, $input, $idx..]

  # childs after idx need special treatment for relinking
  # cut off the tail after $idx
  my @tail_childs = splice @{ $node->{childs} }, $idx;

  # push $input at end of childs
  push @{ $node->{childs} }, $input;

  # now handle the tail of the childs [idx:]
  # we can't just append the rest, maybe new input child contains next childs in row
  while ( my $child = shift @tail_childs ) {

    # relink next child in row if contained in new input node
    if ( $input->{block}->contains( $child->{block} ) ) {

      # insert or return undef
      $input->_insert_node($child) // die("logic error,");
      next;
    }

    # childs are sorted, stop relinking after first child not contained in new input node
    # just copy this child and tail
    push @{ $node->{childs} }, $child, @tail_childs;

    # ready
    last;
  }

  # success
  return 1;
}

####
# _remove($block, $branch)
#
# Remove block in node or childs of node, returns undef if not found.
# If $branch is true, don't relink the child nodes.
#
#   $node->_remove($block, $branch) // warn("block not found,");
#

sub _remove {
  my ( $node, $that, $del_branch ) = @_;
  #
  # number of childs, return undef (false) if 0
  my $nc = scalar @{ $node->{childs} } || return;

  # childs are sorted find pos in childs on this level
  # find first index where child->{block} >= that
  my $idx = List::MoreUtils::lower_bound { $_->{block}->cmp($that) } @{ $node->{childs} };

  # found by exact match?
  # search index may be at $nc, take care for index panics
  if ( $idx < $nc ) {
    if ( $node->{childs}[$idx]->{block}->cmp($that) == 0 ) {

      # save for relinking of grandchilds
      my $match = $node->{childs}[$idx] unless $del_branch;

      # cut-off this child at idx from node
      splice @{ $node->{childs} }, $idx, 1;

      # if we are in remove branch mode, stop here, no relinking of grand childs
      # success
      return 1 if $del_branch;

      # re-insert grand_childs from deleted child into tree
      foreach my $grand_child ( @{ $match->{childs} } ) {
        $node->_insert_node($grand_child) or die("logic error,");
      }

      # success
      return 1;
    }
  }

  # no exact match at this level, check if child before idx contains the input?
  # search index may be 0, take care for index panics
  if ( $idx > 0 ) {

    # child before idx may contain the item, recdescent
    my $prev = $node->{childs}[ $idx - 1 ];
    if ( $prev->{block}->contains($that) ) {
      return $prev->_remove( $that, $del_branch );
    }
  }

  # not equal to any child and not contained in any child
  # failed
  return;
}

####
# _contains($block)
#
# Reports whether the given block is contained in any child of the node.
#
# block is a Net::IPAM::Block or a subclass
#
# returns the outermost containing block

sub _contains {
  my ( $node, $block ) = @_;
  #
  # number of childs, return undef (false) if 0
  my $nc = scalar @{ $node->{childs} } || return;

  # childs are sorted find pos in childs
  # find first index where child->{block} >= block
  my $idx = List::MoreUtils::lower_bound { $_->{block}->cmp($block) } @{ $node->{childs} };

  # search index may be at $nc, take care for index panics
  if ( $idx < $nc ) {

    # child at idx may be equal to item
    if ( $block->cmp( $node->{childs}[$idx]->{block} ) == 0 ) {
      return $block;
    }
  }

  # search index may be 0 and blocks are not equal (see above), return undef (false)
  return if $idx == 0;

  # child before idx may contain the item
  return $node->{childs}[ $idx - 1 ]{block} if $node->{childs}[ $idx - 1 ]{block}->contains($block);

  return;
}

####
# _lookup($block)
#
# Returns item in tree with longest-prefix-match for $block, returns undef if not found.
#
# block is a Net::IPAM::Block or a subclass
#
# returns the lpm block

sub _lookup {
  my ( $node, $block ) = @_;
  #
  # number of childs, return undef if we have no childs
  my $nc = scalar @{ $node->{childs} } || return;

  # childs are sorted find pos in childs on this level
  # find first index where child->{block} >= block
  my $idx = List::MoreUtils::lower_bound { $_->{block}->cmp($block) } @{ $node->{childs} };

  # found by exact match?
  if ( $idx < $nc ) {
    if ( $node->{childs}[$idx]->{block}->cmp($block) == 0 ) {
      return $node->{childs}[$idx]->{block};
    }
  }

  # look if child before idx contains block
  # search index may be 0, take care for index panics
  if ( $idx > 0 ) {

    # make alias, better to read or debug
    my $this = $node->{childs}[ $idx - 1 ];

    if ( $this->{block}->contains($block) ) {

      # return this block as longest-prefix-match if there are no more childs
      return $this->{block} if @{ $this->{childs} } == 0;

      # recursive descent
      return $this->_lookup($block);
    }
  }

  # return this block as longest-prefix-match
  return $node->{block};
}

=head1 AUTHOR

Karl Gaissmaier, C<< <karl.gaissmaier(at)uni-ulm.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ipam-tree at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IPAM-Tree>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IPAM::Tree::Node

You can also look for information at:

=over 4

=item * on github

TODO

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=encoding utf8


=cut

1;    # End of Net::IPAM::Tree::Node
