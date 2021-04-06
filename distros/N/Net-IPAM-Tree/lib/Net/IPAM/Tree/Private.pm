package Net::IPAM::Tree::Private;

use 5.10.0;
use strict;
use warnings;
use utf8;
use List::MoreUtils qw();

=head1 NAME

Net::IPAM::Tree::Private - private implementation for Net::IPAM::Tree

=head1 SYNOPSIS

This module is not useful standalone, it's just needed for Net::IPAM::Tree.
The implementation details are hidden by the public API in Net::IPAM::Tree.

=head1 FUNCTIONS

=head2 _buildIndexTree($tree, $parent, $child)

Building the tree with just the array indices, the sorted items itself are not moved.
create the {parent}->[childs] map, rec-descent algo.

=cut

sub _build_index_tree {
  my ( $t, $parent, $child ) = @_;

  # if parent has no childs yet, just append the child idx
  if ( not defined $t->{_tree}{$parent} ) {
    push @{ $t->{_tree}{$parent} }, $child;
    return;
  }

  # everything is sorted, just look for previous child for coverage

  # get prev child idx for this parent
  my $prev = $t->{_tree}{$parent}[-1];

  # item is covered by previous child, it's an ancestot, not a sibling
  if ( $t->{_items}[$prev]->contains( $t->{_items}[$child] ) ) {

    # rec-descent
    _build_index_tree( $t, $prev, $child );
    return;
  }

  # not covered by previous child, append as sibling
  push @{ $t->{_tree}{$parent} }, $child;

  return;
}

####
# _superset($block)
#
# returns the outermost containing block or undef
sub _superset {
  my ( $t, $thing ) = @_;

  # find first item in root-level equal to or superset of block
  for my $i ( @{ $t->{_tree}{_ROOT} } ) {
    if ( $t->{_items}[$i]->cmp($thing) == 0 || $t->{_items}[$i]->contains($thing) ) {
      return $t->{_items}[$i];
    }
  }

  return;
}

####
# _lookup($block)
#
# Returns item in tree with longest-prefix-match for $block, returns undef if not found.
#
# thing is a Net::IPAM::Block or a subclass of them
#
# returns the lpm block
#
# rec-descent algo
sub _lookup {
  my ( $t, $parent, $block ) = @_;

  # derefernce child idxs array
  my $c_idxs = $t->{_tree}{$parent};

  # find first index where child->{block} >= block
  my $idx =
    List::MoreUtils::lower_bound { $t->{_items}[$_]->cmp($block) } @$c_idxs;

  # found by exact match?
  # search index may be -1 or at end, take care for index panics
  if ( $idx >= 0 and $idx < @$c_idxs ) {

    # deref for better reading and debugging
    my $i = $c_idxs->[$idx];

    if ( $t->{_items}[$i]->cmp($block) == 0 ) {
      return $t->{_items}[$i];
    }
  }

  # look if child before idx contains block
  # search index may be 0, take care for index panics
  if ( $idx > 0 ) {

    # deref for better reading and debugging
    my $i = $c_idxs->[ $idx - 1 ];

    if ( $t->{_items}[$i]->contains($block) ) {

      # rec-descent
      return _lookup( $t, $i, $block );
    }
  }

  # return parent at this level, if root returns undef
  if ( $parent eq '_ROOT' ) {
    return;
  }

  return $t->{_items}[$parent];
}

# recdescent to string
sub _to_string {
  my ( $t, $cb, $parent, $buf, $prefix ) = @_;

  my $c_idxs = $t->{_tree}{$parent};

  # STOP condition, no more childs
  unless ( defined $c_idxs ) {
    return $buf;
  }

  my $len_c = @$c_idxs;

  # stop before last child
  for my $i ( @{$c_idxs}[ 0 .. $len_c - 2 ] ) {
    $buf .= $prefix . "├─ " . $cb->( $t->{_items}[$i] ) . "\n";
    $buf = _to_string( $t, $cb, $i, $buf, $prefix . "│  " );
  }

  # last child
  my $i = $c_idxs->[-1];
  $buf .= $prefix . "└─ " . $cb->( $t->{_items}[$i] ) . "\n";
  $buf = _to_string( $t, $cb, $i, $buf, $prefix . "   " );

  return $buf;
}

# walk the tree, call the cb for every item with:
#  my $err = $cb->(
#    {
#      depth  => $depth,
#      item   => $item,
#      parent => $parent,
#      childs => [@childs],
#    }
#  );
#
sub _walk {
  my ( $t, $cb, $depth, $p, $i ) = @_;

  my $parent;
  if ( defined $p ) {
    $parent = $t->{_items}[$p];
  }

  my $item   = $t->{_items}[$i];
  my $c_idxs = $t->{_tree}{$i};

  my @childs;
  foreach my $c (@$c_idxs) {
    push @childs, $t->{_items}[$c];
  }

  my $err = $cb->(
    {
      depth  => $depth,
      item   => $item,
      parent => $parent,
      childs => [@childs],
    }
  );

  return $err if $err;

  foreach my $c (@$c_idxs) {
    my $err = _walk( $t, $cb, $depth + 1, $i, $c );
    return $err if $err;
  }

  return;
}

=head1 AUTHOR

Karl Gaissmaier, C<< <karl.gaissmaier(at)uni-ulm.de> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IPAM::Tree::Private

You can also look for information at:

=over 4

=item * on github

TODO

=back

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2021 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=encoding utf8


=cut

1;
