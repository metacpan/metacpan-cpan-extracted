
package TUI::Objects::NSSortedCollection;
# ABSTRACT: Defines the class TNSSortedCollection

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TNSSortedCollection
  new_TNSSortedCollection
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Objects::Const qw( ccNotFound );
use TUI::Objects::NSCollection;

sub TNSSortedCollection() { __PACKAGE__ }
sub new_TNSSortedCollection { __PACKAGE__->from(@_) }

extends TNSCollection;

# import global variables
use vars qw(
  %ITEMS 
);
{
  no strict 'refs';
  *ITEMS = \%{ TNSCollection . '::ITEMS' };
}

# public attributes
has duplicates => ( is => 'rw', default => false );

sub search {    # $bool ($key|undef, \$index)
  state $sig = signature(
    method => Object,
    pos    => [Any, ScalarRef],
  );
  my ( $self, $key, $index_ref ) = $sig->( @_ );
  my $l   = 0;
  my $h   = $self->{count} - 1;
  my $res = false;
  while ( $l <= $h ) {
    my $i = ( $l + $h ) >> 1;
    my $item = $ITEMS{ $self->{items}->[$i] };
    my $c = $self->compare( $self->keyOf( $item ), $key );
    if ( $c < 0 ) {
      $l = $i + 1;
    }
    else {
      $h = $i - 1;
      if ( $c == 0 ) {
        $res = true;
        $l   = $i unless $self->{duplicates};
      }
    }
  } #/ while ( $l <= $h )
  $$index_ref = $l;
  return $res;
} #/ sub search

sub indexOf {    # $index ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $i;
  if ( !$self->search( $self->keyOf( $item ), \$i ) ) {
    return ccNotFound;
  }
  else {
    if ( $self->{duplicates} ) {
      while ( $i < $self->{count} && $item ne $ITEMS{ $self->{items}->[$i] } ) {
        $i++;
      }
    }
    return $i < $self->{count} ? $i : ccNotFound;
  }
} #/ sub indexOf

sub insert {    # $index ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $i;
  if ( !$self->search( $self->keyOf( $item ), \$i ) || $self->{duplicates} ) {
    $self->atInsert( $i, $item );
  }
  return $i;
}

sub keyOf {    # $key ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $item;
}

sub compare {    # $cmp ($key1, $key2)
  state $sig = signature(
    method => Object,
    pos    => [Any, Any],
  );
  $sig->( @_ );
  return 0;
}

1

__END__

=pod

=head1 NAME

TUI::Objects::NSSortedCollection - internal non-storable base for sorted coll's

=head1 DESCRIPTION

C<TNSSortedCollection> is the non-storable base variant of sorted collection
classes in the TUI::Vision framework. It extends C<TNSCollection> with support
for ordered insertion and lookup.

This class exists primarily for internal use by the framework. Public-facing
code should use C<TSortedCollection> or one of its derived classes instead.

The non-storable variants are required to separate internal collection behavior
from the storable collection types used elsewhere in the library.

=head1 NOTE

This class is considered internal.

Although C<TNSSortedCollection> implements the core behavior required for
sorted collections, it is not intended to be instantiated or subclassed
directly by application code.

Derived public classes are expected to provide a concrete comparison strategy.

=head1 SEE ALSO

L<TUI::Objects::SortedCollection>,
L<TUI::Objects::Collection>,
L<TUI::Objects::NSCollection>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2024-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
