package TUI::Objects::StringCollection;
# ABSTRACT: Implement a string collection for the framework.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStringCollection
  new_TStringCollection
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Objects::Const qw( ccNotFound );
use TUI::Objects::SortedCollection;

sub TStringCollection() { __PACKAGE__ }
sub name() { 'TStringCollection' };
sub new_TStringCollection { __PACKAGE__->from(@_) }

extends TSortedCollection;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      limit => Int, { alias => 'aLimit' },
      delta => Int, { alias => 'aDelta' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($aLimit, $aDelta)
  state $sig = signature(
    method => 1,
    pos => [Int, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( limit => $args[0], delta => $args[1] );
}

sub compare {    # $cmp ($key1, $key2)
  state $sig = signature(
    method => Object,
    pos    => [Str, Str],
  );
  my ( $self, $key1, $key2 ) = $sig->( @_ );
  return $key1 cmp $key2;
}

1

__END__

=pod

=head1 NAME

TStringCollection - sorted collection specialized for strings

=head1 HIERARCHY

  TObject
    TCollection
      TSortedCollection
        TStringCollection

=head1 SYNOPSIS

  use TUI::Objects;

  my $coll = TStringCollection->new(
    limit => 100,
    delta => 20
  );

  $coll->insert("alpha");
  $coll->insert("beta");

=head1 DESCRIPTION

C<TStringCollection> is a specialized variant of C<TSortedCollection> designed
for storing and managing collections of strings. It provides a ready-to-use
implementation that maintains its elements in sorted order using string
comparison semantics.

Unlike its base class, C<TStringCollection> supplies concrete implementations
for key extraction, comparison, and item management. This allows string data
to be stored, sorted, and serialized without requiring subclasses to override
any behavior.

Apart from its string-specific functionality, all collection management
features are inherited unchanged from C<TSortedCollection>.

=head1 CONSTRUCTOR

=head2 new

  my $coll = TStringCollection->new(
    limit => $limit,
    delta => $delta
  );

Creates a new string collection with the specified initial capacity and growth
policy.

=over

=item limit

Initial capacity of the collection (I<Int>).

=item delta

Growth increment of the collection (I<Int>).  
A value of zero disables automatic growth.

=back

=head2 new_TStringCollection

  my $coll = new_TStringCollection($limit, $delta);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 compare

  my $cmp = $coll->compare($key1, $key2);

Compares two keys as strings and returns an integer indicating their relative
order.

The return value follows the standard convention:

=over 4

=item *

negative value if C<$key1> is less than C<$key2>

=item *

zero if both strings are equal

=item *

positive value if C<$key1> is greater than C<$key2>

=back

=head1 SEE ALSO

L<TSortedCollection>, L<TCollection>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
