package Net::IPAM::Tree;

our $VERSION = '3.00';

use 5.10.0;
use strict;
use warnings;
use utf8;

use Carp qw();
use Scalar::Util qw();

use Net::IPAM::Tree::Private qw();
use Net::IPAM::Block qw();

=head1 NAME

Net::IPAM::Tree - A CIDR/Block tree library for fast IP lookup with longest-prefix-match.

=head1 DESCRIPTION

A module for fast IP-routing-table lookups and IP-ACLs (Access Control Lists).

It is B<NOT> a standard patricia-trie implementation.
This isn't possible for general blocks not represented by bitmasks.
Every tree item is a Net::IPAM::Block or a subclass of it.

=encoding utf8

=head1 SYNOPSIS

  use Net::IPAM::Tree;

  my ($t, $dups) = Net::IPAM::Tree->new(@blocks);
  if (@$dups) {
    warn("items are duplicate: " . join("\n", @$dups));
  }

  my $block = $t->lookup($ip_or_block)
    && printf( "longest-prefix-match in tree for %s is %s\n", $ip_or_block, $block );

  my $superset = $t->superset($ip_or_block)
    && printf( "superset in tree for ip or block %s is %s\n", $ip_or_block, $superset );

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

=head2 new(@blocks)

Create Net::IPAM::Tree object.

  my ($t, $dups) = Net::IPAM::Tree->new(@blocks);

In scalar context just returns the tree object, duplicate items produce a warning.

In list context returns the tree object and the arrayref of duplicate items, if any.

=cut

sub new {
  my $self = bless {}, shift;

  $self->{_items} = [ Net::IPAM::Block::sort_block(@_) ];
  $self->{_tree}  = {};                                     # {parent_idx}->[child_idxs]

  my @dups;
  for ( my $i = 0 ; $i < @{ $self->{_items} } ; $i++ ) {

    # check for dups
    if ( $i > 0 && $self->{_items}[$i]->cmp( $self->{_items}[ $i - 1 ] ) == 0 ) {
      push @dups, $self->{_items}[$i];
      next;
    }

    Net::IPAM::Tree::Private::_build_index_tree( $self, '_ROOT', $i );
  }

  if (wantarray) {
    return ( $self, \@dups );
  }

  if (@dups) {
    Carp::carp('duplicate items,');
  }

  return $self;
}

=head2 superset($thing)

Returns the outermost block if the given $thing (L<Net::IPAM::IP> or L<Net::IPAM::Block>)
is contained in the tree or undef.

=cut

sub superset {
  my ( $self, $thing ) = @_;
  Carp::croak("missing or wrong arg,") unless Scalar::Util::blessed($thing);

  # make a /32 or /128 block if thing is an IP
  $thing = Net::IPAM::Block->new($thing) if $thing->isa('Net::IPAM::IP');

  Carp::croak("wrong arg,") unless $thing->isa('Net::IPAM::Block');

  return Net::IPAM::Tree::Private::_superset( $self, $thing );
}

=head2 lookup($thing)

Returns L<Net::IPAM::Block> with longest prefix match for $thing (L<Net::IPAM::IP> or L<Net::IPAM::Block>)
in the tree, undef if not found.

This can be used for ACL or fast routing table lookups.

  # make blocks
  my @priv = map { Net::IPAM::Block->new($_) } qw(10.0.0.0/8 172.16.0.0/12 192.168.0.0 fc00::/7);

  # make tree
  my $priv = Net::IPAM::Tree->new(@priv);

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

  return Net::IPAM::Tree::Private::_lookup( $self, '_ROOT', $thing );
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
  my ( $self, $cb ) = @_;

  if ( defined $cb ) {
    Carp::croak("attribute 'cb' is no CODE_REF,") unless ref $cb eq 'CODE';
  }
  else {
    $cb = sub { return "$_[0]" };
  }

  my $prefix = '';
  my $buf    = '';

  $buf = Net::IPAM::Tree::Private::_to_string( $self, $cb, '_ROOT', $buf, $prefix );

  return "▼\n" . $buf if $buf;
  return;
}

=head2 walk

Walks the ordered tree, see L<to_string()>.

  my $err_string = $t->walk($callback);

For every item the callback function is called with the following hash-ref:

    my $err = $callback->(
      {
        depth  => $i,           # starts at 0
        item   => $item,        # current block
        parent => $parent,      # parent block, undef for root items
        childs => [@childs],    # child blocks, empty for leaf items
      }
    );

The current depth is counting from 0.

On error, the walk is stopped and the error is returned to the caller.
The callback B<MUST> return undef if there is no error!

=cut

sub walk {
  my ( $self, $cb ) = @_;
  Carp::croak("missing arg,")                        unless defined $cb;
  Carp::croak("wrong arg, callback is no CODE_REF,") unless ref $cb eq 'CODE';

  foreach my $c ( @{ $self->{_tree}{_ROOT} } ) {
    my $err = Net::IPAM::Tree::Private::_walk( $self, $cb, 0, undef, $c );
    return $err if defined $err;
  }

  return;
}

=head2 len

Returns the number of blocks in the tree.

=cut

sub len {
  return scalar @{ $_[0]->{_items} };
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

L<Net::IPAM::IP>
L<Net::IPAM::Block>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2021 by Karl Gaissmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;    # End of Net::IPAM::Tree
