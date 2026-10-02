package TUI::ColorSel::ColorItem;
# ABSTRACT: singly linked color item used by color dialog structures

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TColorItem
  new_TColorItem
);

use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

sub TColorItem() { __PACKAGE__ }
sub new_TColorItem { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = (
    name  => sub { '' },
    index => sub { 0 },
    next  => sub { undef },
  );
}

sub new {    # \$item (%args)
  state $sig = signature(
    method => 1,
    named  => [
      name  => Str,               { alias => 'nm' },
      index => PositiveOrZeroInt, { alias => 'idx' },
      next  => Maybe[Object],     { alias => 'nxt', optional => 1 },
    ],
  );
  my ( $class, $self ) = $sig->( @_ );
  $self->{$_} = $HAS{$_}->()
    for grep { not exists $self->{$_} } keys %HAS;
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $item ($nm, $idx, |$nxt)
  state $sig = signature(
    method => 1,
    pos    => [
      Str,
      PositiveOrZeroInt, 
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( name => $args[0], index => $args[1], next => $args[2] );
}

sub add {    # $i1 ($i1, $i2, |$swap)
  state $sig = signature(
    pos => [
      Object,
      Object,
      Bool, { optional => 1 } 
    ],
  );
  my ( $i1, $i2, $swap ) = $sig->( @_ );
  assert ( not $swap );    # test if operands have been swapped
  assert ( $i2->isa( TColorItem ) );
  my $cur = $i1;
  $cur = $cur->{next}
    while $cur->{next};
  $cur->{next} = $i2;
  return $i1;
}

use overload
  '+' => \&add,
  fallback => 1;

my $mk_accessors = sub {
  my ( $pkg ) = @_;
  assert ( @_ == 1 );
  assert ( defined $pkg );
  no strict 'refs';
  my %HAS = %{"${pkg}::HAS"};
  for my $field ( keys %HAS ) {
    my $full_name = "${pkg}::$field";
    *$full_name = sub {
      assert ( is_Object $_[0] );
      if ( @_ > 1 ) {
        $_[0]->{$field} = $_[1];
      }
      $_[0]->{$field};
    };
  }
};

__PACKAGE__->$mk_accessors();

1

__END__

=pod

=head1 NAME

TUI::ColorSel::ColorItem - linked color item used by color dialog structures

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $item1 = TColorItem->new(
    name  => 'Desktop',
    index => 0,
  );

  my $item2 = TColorItem->new(
    name  => 'Menu',
    index => 1,
  );

  my $list = $item1 + $item2;

  my $name  = $item1->name;
  my $index = $item1->index;

=head1 DESCRIPTION

C<TColorItem> represents a singly linked list element used by L<TUI::Vision> 
color selection infrastructure.

Each node stores a display name, an index value and an optional reference to 
the next item in the list. The structure mirrors the original I<Turbo Vision> 
data model closely and is primarily used to describe available color groups and 
color entries.

Like the original Borland implementation, items are linked together through a
simple forward list. Perl's automatic memory management removes the need
for explicit allocation and disposal while preserving the original behavior.

The overloaded C<+> operator provides a convenient way to append items to
an existing chain while preserving the original I<Turbo Vision> programming
style.

=head1 ATTRIBUTES

=head2 name

Display name associated with this item (I<Str>).

=head2 index

Numeric index associated with this item (I<PositiveOrZeroInt>).

=head2 next

Reference to the next list element (I<TColorItem>), or C<undef> if this is the 
last item.

=head1 CONSTRUCTOR

=head2 new

  my $item = TColorItem->new(
    name  => $name,
    index => $index,
    next  => $next,
  );

Creates a new color item.

=over

=item name

Display name of the item (I<Str>).

=item index

Associated numeric index (I<PositiveOrZeroInt>).

=item next

Reference to the next item in the list, or C<undef> (I<TColorItem> or undef).

=back

=head2 new_TColorItem

  my $item = new_TColorItem( $name, $index, $next | undef );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 add

  my $item = $item1->add($item2);

Adds a color item to the end of the current list.

This method implements the C<+> operator, allowing color items to be chained 
together.

=head1 OPERATORS

=head2 +

  my $list = $item1 + $item2;

Appends C<$item2> to the end of the list beginning at C<$item1>.

The operation returns the head element of the resulting list, allowing
multiple append operations to be chained.

=head1 SEE ALSO

L<TColorGroup|TUI::Dialogs::ColorGroup>,
L<TColorDialog|TUI::ColorSel::TColorDialog>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file,
which is part of the distribution).

=cut
