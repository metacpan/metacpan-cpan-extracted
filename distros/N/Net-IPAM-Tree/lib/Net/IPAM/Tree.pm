package Net::IPAM::Tree;

our $VERSION = '1.12';

use 5.10.0;
use strict;
use warnings;
use utf8;

use Carp qw();
use Scalar::Util qw();

use Net::IPAM::Block;
use Net::IPAM::Tree::Node;

=head1 NAME

Net::IPAM::Tree - A CIDR/Block tree library for fast IP lookup with longest-prefix-match.

=head1 DESCRIPTION

A module for fast IP-routing-table lookups and IP-ACLs (Access Control Lists).

It is B<NOT> a standard patricia-trie implementation.
This isn't possible for general blocks not represented by bitmasks, every tree item is a Net::IPAM::Block.

The complexity for tree operations is in worst case O(h * log n) with h <= 128 (IPv6) or h <=32 (IPv4).

=encoding utf8

=head1 SYNOPSIS

  use Net::IPAM::Tree;

  my $t = Net::IPAM::Tree->new();

  $t->insert(@blocks) || die("duplicate block...");
  $t->remove($block)  || warn("block not in tree...");

  my $block = $t->lookup($ip_or_block)
    && printf( "longest-prefix-match in tree for %s is %s\n", $ip_or_block, $block );

  $t->contains($ip_or_block)
    && printf( "ip or block %s is contained in tree\n", $ip_or_block );

  say $t->to_string;

  ▼
  ├─ ::/8
  ├─ 100::/8
  ├─ 2000::/3
  │  ├─ 2000::/4
  │  └─ 3000::/4
  ├─ 4000::/3
  ...

=head1 METHODS

=head2 new([$error_cb])

Create Net::IPAM::Tree object.

  my $t = Net::IPAM::Tree->new;

The only optional argument is a coderef for an error handler.
With no error callback L</insert> just calls C<< carp() >> on duplicate items.

The error callback gets the duplicate block as argument.

=cut

sub new {
  my $self = bless {}, $_[0];

  $self->{root} = Net::IPAM::Tree::Node->new(
    {
      block  => undef,
      parent => undef,
      childs => [],
    }
  );

  if ( ref $_[1] eq 'CODE' ) {
    $self->{error_cb} = $_[1];
  }
  else {
    $self->{error_cb} = sub { Carp::carp("duplicate block during insert: $_[0]") };
  }

  return $self;
}

=head2 insert

Insert block(s) into the tree. Inserting a bulk of blocks is much faster
than inserting unsorted single blocks in a loop.

Returns the tree object on success for method chaining.

  my $t = Net::IPAM::Tree->new->insert(@blocks) // die("one or more blocks are duplicate");

Returns undef on duplicate blocks in the tree and generate warnings.
To shut up the warnings on duplicate items, define your own error callback in the constructor.

  my $t = Net::IPAM::Tree->new(sub{});
  $t->insert(@blocks) // die("one or more blocks are duplicate");

=cut

sub insert {
  my ( $self, @blocks ) = @_;

  if ( scalar @blocks > 1 ) {

    # sort before insert, makes insertion much faster, no - or at least less - parent-child-relinking needed.
    @blocks = sort { $a->cmp($b) } @blocks;
  }

  my $warnings;
  foreach my $block (@blocks) {
    my $node = Net::IPAM::Tree::Node->new(
      {
        block  => $block,
        parent => undef,
        childs => []
      }
    );

    unless ( defined $self->{root}->_insert_node($node) ) {
      $warnings++;
      $self->{error_cb}->($block);
    }
  }

  # return undef on warning(s)
  return if $warnings;

  # for method chaining
  return $self;
}

=head2 contains($thing)

Returns the outermost block if the given $thing (L<Net::IPAM::IP> or L<Net::IPAM::Block>)
is contained in the tree or undef.

This is much faster than a full L</"lookup"> for the longest-prefix-match.

This can be used for fast ACL lookups.

  # make blocks
  my @deny = map { Net::IPAM::Block->new($_) } qw(2001:db8::-2001:db8::1234:ffea fe80::/10);

  # make tree
  my $deny = Net::IPAM::Tree->new->insert(@deny) or die;

  my $ip = Net::IPAM::IP->new( get_ip_from($some_request) );
  say "request forbidden for $ip" if $deny->contains($ip);

=cut

sub contains {
  my ( $self, $thing ) = @_;
  Carp::croak("missing or wrong arg,") unless Scalar::Util::blessed($thing);

  # make a /32 or /128 block if thing is an IP
  $thing = Net::IPAM::Block->new($thing) if $thing->isa('Net::IPAM::IP');

  Carp::croak("wrong arg,") unless $thing->isa('Net::IPAM::Block');

  # just look in childs of root node
  return $self->{root}->_contains($thing);
}

=head2 lookup($thing)

Returns L<Net::IPAM::Block> with longest prefix match for $thing (L<Net::IPAM::IP> or L<Net::IPAM::Block>)
in the tree, undef if not found.

This can be used for fast routing table lookups.

  # make blocks
  my @priv = map { Net::IPAM::Block->new($_) } qw(10.0.0.0/8 172.16.0.0/12 192.168.0.0 fc00::/7);

  # make tree
  my $priv = Net::IPAM::Tree->new->insert(@priv) or die;

  my $b = Net::IPAM::Block->new('fdcd:aa59:8bce::/48') or die;

  my $lpm = $priv->lookup($b)
    && say "longest-prefix-match for $b is $lpm";

=cut

sub lookup {
  my ( $self, $thing ) = @_;
  Carp::croak("missing or wrong arg,") unless Scalar::Util::blessed($thing);

  # make a /32 or /128 block if thing is an IP
  $thing = Net::IPAM::Block->new($thing) if $thing->isa('Net::IPAM::IP');

  Carp::croak("wrong arg,") unless $thing->isa('Net::IPAM::Block');

  return $self->{root}->_lookup($thing);
}

=head2 remove

Remove one block from tree, relink parent/child relation at the gap.

  $t->remove($block) // warn("block not found");

Returns undef if $block is not found.

=cut

sub remove {
  Carp::croak("missing or wrong arg,") unless Scalar::Util::blessed( $_[1] );
  Carp::croak("wrong arg,") unless $_[1]->isa('Net::IPAM::Block');

  # remove block, relink childs
  return $_[0]->{root}->_remove( $_[1], 0 );
}

=head2 remove_branch

Remove $block and the branch below from tree.

  $t->remove_branch($block) // warn("block not found");

Returns undef if $block is not found.

=cut

sub remove_branch {
  Carp::croak("missing or wrong arg,") unless Scalar::Util::blessed( $_[1] );
  Carp::croak("wrong arg,") unless $_[1]->isa('Net::IPAM::Block');

  # remove block and child nodes
  return $_[0]->{root}->_remove( $_[1], 1 );
}

=head2 to_string

Returns the tree as ordered graph or undef on empty trees.

  $t->to_string($callback);

The optional callback is called on every block. Returns the decorated string for block.

  $t->to_string( sub { my $block = shift; return decorate($block) } );

example (without callback):

  ▼
  ├─ ::/8
  ├─ 100::/8
  ├─ 2000::/3
  │  ├─ 2000::/4
  │  └─ 3000::/4
  ├─ 6000::/3

possible example (with callback):

  ▼
  ├─ ::/8.................   "Reserved by IETF     [RFC3513][RFC4291]"
  ├─ 100::/8..............   "Reserved by IETF     [RFC3513][RFC4291]"
  ├─ 2000::/3.............   "Global Unicast       [RFC3513][RFC4291]"
  │  ├─ 2000::/4.............  "Test"
  │  └─ 3000::/4.............  "FREE"
  ├─ 6000::/3.............   "Reserved by IETF     [RFC3513][RFC4291]"

=cut

sub to_string {
  my ( $self, $block_to_str ) = @_;

  if ( defined $block_to_str ) {
    Carp::croak("attribute 'cb' is no CODE_REF,") unless ref $block_to_str eq 'CODE';
  }
  else {
    $block_to_str = sub { return "$_[0]" };
  }

  # string buffer, filled by closure
  my $buf;

  # recdescent algo
  my $walk_and_stringify;

  $walk_and_stringify = sub {
    my ( $node, $prefix ) = @_;

    # number of child nodes
    my $nc = $node->childs;

    return if $nc == 0;

    for ( my $i = 0 ; $i < $nc ; $i++ ) {

      # last child?
      if ( $i == $nc - 1 ) {
        $buf .= sprintf( "%s%s\n", $prefix . '└─ ', $block_to_str->( $node->{childs}[$i]{block} ) );
        $walk_and_stringify->( $node->{childs}[$i], $prefix . '   ' );
      }
      else {
        $buf .= sprintf( "%s%s\n", $prefix . '├─ ', $block_to_str->( $node->{childs}[$i]{block} ) );
        $walk_and_stringify->( $node->{childs}[$i], $prefix . '│  ' );
      }
    }
  };

  $walk_and_stringify->( $self->{root}, '' );

  return "▼\n" . $buf if defined $buf;
  return;
}

=head2 walk

Walks the tree, starting at root node in depth first order.

  my $err_string = $t->walk($callback);

For every node L<Net::IPAM::Tree::Node> the callback function is called with the node
and the current depth (counting from 0) as arguments.

	my $err_string = $callback->($node, $depth);

The callback must return undef if there is no error!
On error, the walk is stopped and the error is returned to the caller.

Example, get some tree statistics:

  my ( $n, $max_d, $max_c ) = ( 0, 0, 0 );

  my $cb = sub {
    my ( $node, $depth ) = @_;

    $n++;
    $max_c = $node->childs if $max_c < $node->childs;
    $max_d = $depth + 1    if $max_d < $depth + 1;

    return;    # explicit return (undef) if there is no error!
  };

  my $err = $t->walk($cb);
  say "tree has $n nodes and is $max_d levels deep, the number of max childs/node is $max_c" unless $err;

=cut

sub walk {
  my ( $self, $cb ) = @_;
  Carp::croak("missing arg,") unless defined $cb;
  Carp::croak("wrong arg, callback is no CODE_REF,") unless ref $cb eq 'CODE';

  # recursive func, declare ahead
  my $walk_rec;

  $walk_rec = sub {
    my ( $node, $depth ) = @_;

    my $err = $cb->( $node, $depth );
    return $err if $err;

    # walk the childs
    foreach my $child ( $node->childs ) {
      my $err = $walk_rec->( $child, $depth + 1 );
      return $err if $err;
    }

    return;
  };

  # start at root node
  foreach my $child ( $self->{root}->childs ) {
    my $err = $walk_rec->( $child, 0 );
    return $err if $err;
  }

  return;
}

=head2 len

Just for convenience, L</"len"> returns the number of blocks in the tree,
implemented as a simple L</"walk"> callback.

=cut

sub len {
  my $self = shift;

  my $n;
  my $counter_cb = sub { $n++; return };

  my $err = $self->walk($counter_cb);
  Carp::croak($err) if defined $err;

  return $n;
}

=head1 AUTHOR

Karl Gaissmaier, C<< <karl.gaissmaier(at)uni-ulm.de> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IPAM::Tree

You can also look for information at:

=over 4

=item * on github

TODO

=back

=head1 SEE ALSO

L<Net::IPAM::Tree::Node>
L<Net::IPAM::IP>
L<Net::IPAM::Block>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;    # End of Net::IPAM::Tree
