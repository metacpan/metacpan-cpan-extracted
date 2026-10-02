package TUI::ColorSel::ColorGroup;
# ABSTRACT: linked color group definition used by color selection dialogs

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TColorGroup
  new_TColorGroup
);

use Class::Struct;
use Devel::StrictMode;
use if STRICT => 'Hash::Util';
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::ColorSel::ColorItem;

struct TColorIndex => [
  groupIndex => '$',
  colorSize  => '$',
  colorIndex => '@',
];

sub TColorGroup() { __PACKAGE__ }
sub new_TColorGroup { __PACKAGE__->from(@_) }

# public attributes
our %HAS; BEGIN {
  %HAS = (
    name  => sub { '' },
    index => sub { 0 },
    items => sub { undef },
    next  => sub { undef },
  );
}

# predeclare private methods
my (
  $add_color_item,
  $add_color_group,
);

sub new {    # \$item (%args)
  state $sig = signature(
    method => 1,
    named  => [
      name  => Str,           { alias => 'nm' },
      items => Maybe[Object], { alias => 'itm', optional => 1 },
      next  => Maybe[Object], { alias => 'nxt', optional => 1 },
    ],
  );
  my ( $class, $self ) = $sig->( @_ );
  $self->{$_} = $HAS{$_}->()
    for grep { not exists $self->{$_} } keys %HAS;
  bless $self, $class;
  Hash::Util::lock_keys( %$self ) if STRICT;
  return $self;
}

sub from {    # $item ($nm, |$itm, |$nxt)
  state $sig = signature(
    method => 1,
    pos    => [
      Str,
      Maybe[Object], { optional => 1 },
      Maybe[Object], { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( name => $args[0], items => $args[1], next => $args[2] );
}

sub _add_color_item { goto &$add_color_item }
$add_color_item = sub {    # $g ($g, $i, |undef)
  my ( $g, $i ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $g );
  assert ( is_Object $i and $i->isa( TColorItem ) );
  my $grp = $g;
  $grp = $grp->{next}
    while $grp->{next};

  if ( !$grp->{items} ) {
    $grp->{items} = $i;
  }
  else {
    my $cur = $grp->{items};
    $cur = $cur->{next}
      while $cur->{next};
    $cur->{next} = $i;
  }
  return $g;
};

sub _add_color_group { goto &$add_color_group }
$add_color_group = sub {    # $g1 ($g1, $g2, |undef)
  my ( $g1, $g2 ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $g1 );
  assert ( is_Object $g2 and $g2->isa( TColorGroup ) );
  my $cur = $g1;
  $cur = $cur->{next}
    while $cur->{next};
  $cur->{next} = $g2;
  return $g1;
};

sub add {    # $g ($g1, $g2|$i, |$swap)
  state $sig = signature(
    pos => [
      Object,
      Object,
      Bool, { optional => 1 } 
    ],
  );
  my ( $g1, $g2, $swap ) = $sig->( @_ );
  assert ( not $swap );    # test if operands have been swapped
  $g2->isa( TColorGroup )
    ? goto &$add_color_group
    : goto &$add_color_item
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

TUI::ColorSel::ColorGroup - linked color group definition used by color dialog

=head1 SYNOPSIS

  use TUI::ColorSel;

  my $items =
      TColorItem->new(
        name  => 'Normal',
        index => 0
      )
    + TColorItem->new(
        name  => 'Selected',
        index => 1
      );

  my $group = TColorGroup->new(
    name  => 'Desktop',
    items => $items,
  );

  my $name  = $group->name;
  my $items = $group->items;

=head1 DESCRIPTION

C<TColorGroup> represents a color group used by the L<TUI::Vision> color 
selection infrastructure.

Each group contains a display name and a linked list of
L<TColorItem|TUI::Dialogs::ColorItem> objects describing the individual color
entries belonging to the group.

Groups themselves may also be linked together, forming a list of available
color groups.

The Perl implementation preserves the original Borland I<Turbo Vision> data 
model. Each C<TColorGroup> contains a linked list of color items accessible 
through the C<items> attribute. Multiple groups may themselves be linked 
through the C<next> attribute.

The overloaded C<'+'> operator supports the original Borland I<Turbo Vision> 
programming style by allowing both color items and color groups to be appended 
using a uniform syntax.

=head1 ATTRIBUTES

=head2 name

Display name of the color group (I<Str>).

=head2 items

Reference to the first color item in the group, or C<undef> if the group is
empty (I<TColorItem> or C<undef>).

=head2 next

Reference to the next color group, or C<undef> if this is the last group
(I<TColorGroup> or C<undef>).

=head1 CONSTRUCTORS

=head2 new

  my $group = TColorGroup->new(
    name => $name,
    item => $item,
    next => $next,
  );

Creates a new color group.

=over

=item name

Display name of the group (I<Str>).

=item item

Reference to the first color item in the group, or C<undef>
(I<TColorItem> or undef).

=item next

Reference to the next color group, or C<undef>
(I<TColorGroup> or undef).

=back

=head2 new_TColorGroup

  my $group = new_TColorGroup(
    $name,
    $item | undef,
    $next | undef
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 add

  $group = $group->add( $item );

Appends a L<TColorItem|TUI::Dialogs::ColorItem> to the end of the group's
item list.

  $group1 = $group1->add( $group2 );

Appends C<$group2> to the end of the color group chain beginning with
C<$group1>.

In both cases the head of the resulting structure is returned.

=head1 OPERATORS

=head2 +

  $group + $item;

Appends a L<TColorItem|TUI::Dialogs::ColorItem> to the end of the group's
item list.

  $group1 + $group2;

Appends C<$group2> to the end of the color group chain beginning with
C<$group1>.

In both cases the head of the resulting structure is returned.

=head1 SEE ALSO

L<TColorItem|TUI::Dialogs::ColorItem>,
L<TColorDialog|TUI::ColorSel::TColorDialog>

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
