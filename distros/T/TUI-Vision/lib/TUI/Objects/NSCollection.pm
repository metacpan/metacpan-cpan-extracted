package TUI::Objects::NSCollection;
# ABSTRACT: defines the class TNSCollection

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TNSCollection
  new_TNSCollection
);

use Carp ();
use Errno qw( EFAULT EINVAL );
use Hash::Util::FieldHash qw( id );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Objects::Const qw( 
  ccNotFound 
  maxCollectionSize
);
use TUI::Objects::Object;

sub TNSCollection() { __PACKAGE__ }
sub new_TNSCollection { __PACKAGE__->from(@_) }

extends TObject;

# predeclare global variable
our %ITEMS = ();

# protected attributes
has items        => ( is => 'ro', default => [] );
has count        => ( is => 'ro', default => 0 );
has limit        => ( is => 'ro', default => 0 );
has delta        => ( is => 'ro', default => 0 );
has shouldDelete => ( is => 'ro', default => 0 );

# predeclare private methods
my (
  $freeItem,
);

sub BUILDARGS {    # \%args (|%args)
  state $sig = signature(
    method => 1,
    named => [
      limit => Int, { alias => 'aLimit', optional => 1 },
      delta => Int, { alias => 'aDelta', optional => 1 },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->setLimit( $self->{limit} );
  return;
} #/ sub BUILD

sub from {    # $obj ($aLimit, $aDelta)
  state $sig = signature(
    method => 1,
    pos => [
      Int, { optional => 1 },
      Int, { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 0 and return $class->new();
    $_ == 2 and return $class->new( limit => $args[0], delta => $args[1] );
  }
  return;
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->shutDown();
  return;
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  if ( $self->{shouldDelete} ) {
    $self->freeAll();
  }
  else {
    $self->removeAll();
  }
  $self->setLimit( 0 );
  $self->SUPER::shutDown();
  return;
} #/ sub shutDown

sub at {    # $item ($index)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $index ) = $sig->( @_ );
  $self->error( EINVAL, "Index out of bounds" )
    if $index < 0 || $index >= $self->{count};
  return $ITEMS{ $self->{items}->[$index] };
}

sub atRemove {    # void ($index)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $index ) = $sig->( @_ );
  $self->error( EINVAL, "Index out of bounds" )
    if $index < 0 || $index >= $self->{count};
  $self->{count}--;
  splice( @{ $self->{items} }, $index, 1 );
  return;
}

sub atFree {    # void ($index)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $index ) = $sig->( @_ );
  my $item = $self->at( $index );
  $self->atRemove( $index );
  $self->$freeItem( $item );
  return;
}

sub atInsert {    # void ($index, $item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Int, Item],
  );
  my ( $self, $index, $item ) = $sig->( @_ );
  $self->error( EINVAL, "Index out of bounds" )
    if $index < 0;
  $self->setLimit( $self->{count} + $self->{delta} )
    if $self->{count} == $self->{limit};

  my $id = id($item) || 0;
  $ITEMS{ $id } = $item;
  $self->{count}++;

  splice( @{ $self->{items} }, $index, 0, $id );
  return;
}

sub atPut {    # void ($index, $item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Int, Item],
  );
  my ( $self, $index, $item ) = $sig->( @_ );
  $self->error( EINVAL, "Index out of bounds" )
    if $index >= $self->{count};

  my $id = id($item) || 0;
  $ITEMS{ $id } = $item;
  $self->{items}->[$index] = $id;
  return;
}

sub remove {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->atRemove( $self->indexOf( $item ) );
  return;
}

sub removeAll {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{count} = 0;
  $self->{items} = [];
  return;
}

sub free {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->remove( $item );
  $self->$freeItem( $item );
  return;
}

sub freeAll {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->$freeItem( $self->at( $_ ) ) 
    for 0 .. $self->{count} - 1;
  $self->{count} = 0;
  return;
}

sub indexOf {    # $index ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  for my $i ( 0 .. $self->{count} - 1 ) {
    my $id = id($item) || 0;
    return $i if $self->{items}->[$i] eq $id;
  }
  $self->error( EFAULT, "Item not found" );
  return ccNotFound;
}

sub insert {    # $index ($item|undef)
  state $sig = signature(
    method => Object,
    pos    => [Item],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $loc = $self->{count};
  $self->atInsert( $self->{count}, $item );
  return $loc;
}

sub error {    # void ($code, $info)
  state $sig = signature(
    method => Object,
    pos    => [Int, Str],
  );
  my ( $self, $code, $info ) = $sig->( @_ );
  Carp::croak sprintf("Error code: %d, Info: %s\n", $code, $info);
}

sub firstThat {    # $item|undef (\&Test, $arg|undef)
  state $sig = signature(
    method => Object,
    pos    => [CodeRef, Any],
  );
  my ( $self, $Test, $arg ) = $sig->( @_ );
  my $that;
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    return $_ if $Test->( $_, $arg );
  }
  return undef;
}

sub lastThat {    # $item|undef (\&Test, $arg|undef)
  state $sig = signature(
    method => Object,
    pos    => [CodeRef, Any],
  );
  my ( $self, $Test, $arg ) = $sig->( @_ );
  my $that;
  for my $i ( reverse 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    return $_ if $Test->( $_, $arg );
  }
  return undef;
}

sub forEach {    # void (\&action, $arg|undef)
  state $sig = signature(
    method => Object,
    pos    => [CodeRef, Any],
  );
  my ( $self, $action, $arg ) = $sig->( @_ );
  for my $i ( 0 .. $self->{count} - 1 ) {
    local $_ = $ITEMS{ $self->{items}->[$i] };
    $action->( $_, $arg );
  }
  return;
}

sub pack {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $count = 0;
  for my $i ( 0 .. $self->{count} - 1 ) {
    if ( $ITEMS{ $self->{items}->[$i] } ) {
      $count++;
    }
    else {
      splice( @{ $self->{items} }, $i, 1 );
    }
  }
  if ( $self->{count} != $count ) {
    my $n = $self->{count} - $count;
    push( @{ $self->{items} }, ( 0 ) x $n );
    $self->{count} = $count;
  }
  return;
}

sub setLimit {    # void ($aLimit)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $aLimit ) = $sig->( @_ );
  $aLimit = $self->{count} if $aLimit < $self->{count};
  $aLimit = maxCollectionSize if $aLimit > maxCollectionSize;
  if ( $aLimit != $self->{limit} ) {
    my $size = @{ $self->{items} };
    if ( $aLimit > $size ) {
      my $n = $aLimit - $size;
      push( @{ $self->{items} }, ( 0 ) x $n );
    } elsif ( $aLimit < $size ) {
      splice( @{ $self->{items} }, $aLimit );
    }
    $self->{limit} = $aLimit;
  }
  return;
} #/ sub setLimit

sub getCount {    # $count ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{count};
};

$freeItem = sub {
  my ( $self, $item ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  my $id = id($item) || 0;
  delete $ITEMS{ $id } if $id;
  return;
};

1

__END__

=pod

=head1 NAME

TUI::Objects::NSCollection - internal non-storable collection base class

=head1 DESCRIPTION

C<TNSCollection> is the non-storable base variant of the TUI::Vision collection
classes. It exists primarily for internal use, most notably by the stream and
resource management infrastructure.

This class provides the same operational behavior as C<TCollection>, but is not
intended to be used directly by application code. Public-facing code should
always use C<TCollection> or one of its derived classes instead.

The non-storable variants are required to separate internal framework
mechanisms from the storable collection types used elsewhere in the library.

=head1 VARIABLES

=head2 %ITEMS

Internal global hash used to maintain item references for all
C<TCollection> objects.

The collection elements are stored as references in this hash.
Keys are derived using
L<Hash::Util::FieldHash::id|Hash::Util::FieldHash>, ensuring stable and
unique identification of collection items.

This variable is for internal use only and mirrors the reference
handling approach of the original Turbo Vision implementation.

See also L<Scalar::Util::refaddr|Scalar::Util>.

=head1 NOTE

This class is considered internal.

Although C<TNSCollection> implements a full collection interface, it should not
be instantiated or subclassed directly outside of the framework itself.

=head1 SEE ALSO

L<TUI::Objects::Collection>,
L<TUI::Objects::SortedCollection>,
L<TUI::Objects::StringCollection>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
