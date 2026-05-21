package TUI::Menus::StatusDef;
# ABSTRACT: Class linking a range of helps with a list of status line items

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TStatusDef
  new_TStatusDef
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Menus::StatusItem;

sub TStatusDef() { __PACKAGE__ }
sub new_TStatusDef { __PACKAGE__->from(@_) }

# public attributes
has next  => ( is => 'rw' );
has min   => ( is => 'rw', default => sub { die 'required' } );
has max   => ( is => 'rw', default => sub { die 'required' } );
has items => ( is => 'rw' );

# predeclare private methods
my (
  $add_status_item,
  $add_status_def,
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      min   => PositiveOrZeroInt, { alias => 'aMin' },
      max   => PositiveOrZeroInt, { alias => 'aMax' },
      items => Object,            { alias => 'someItems', optional => 1 },
      next  => Object,            { alias => 'aNext',     optional => 1 },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub from {    # $obj ($aMin, $aMax, |$someItems, |$aNext)
  state $sig = signature(
    method => 1,
    pos    => [
      PositiveOrZeroInt,
      PositiveOrZeroInt,
      Object, { optional => 1 },
      Object, { optional => 1 },
    ],
  );
  my ( $class, @args ) = $sig->( @_ );
  SWITCH: for ( scalar @args ) {
    $_ == 2 and return $class->new( min => $args[0], max => $args[1] );
    $_ == 3 and return $class->new( min => $args[0], max => $args[1], 
      items => $args[2] );
    $_ == 4 and return $class->new( min => $args[0], max => $args[1], 
      items => $args[2], next => $args[3] );
  }
  return ;
}

sub _add_status_item { goto &$add_status_item }
$add_status_item = sub {    # $s1 ($s1, $s2, |undef)
  my ( $s1, $s2 ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s1 );
  assert ( is_Object $s2 and $s2->isa( TStatusItem ) );
  my $def = $s1;
  while ( $def->{next} ) {
    $def = $def->{next};
  }
  if ( !$def->{items} ) {
    $def->{items} = $s2;
  }
  else {
    my $cur = $def->{items};
    while ( $cur->{next} ) {
      $cur = $cur->{next};
    }
    $cur->{next} = $s2;
  }
  return $s1;
};

sub _add_status_def { goto &$add_status_def }
$add_status_def = sub {    # $s1 ($s1, $s2, |undef)
  my ( $s1, $s2 ) = @_;
  assert ( @_ >= 2 && @_ <= 3 );
  assert ( is_Object $s1 );
  assert ( is_Object $s2 and $s2->isa( TStatusDef ) );
  my $cur = $s1;
  while ( $cur->{next} ) {
    $cur = $cur->{next};
  }
  $cur->{next} = $s2;
  return $s1;
};

sub add {    # $s1 ($s1, $s2, |$swap)
  state $sig = signature(
    pos => [
      Object,
      Object,
      Bool, { optional => 1 } 
    ],
  );
  my ( $s1, $s2, $swap ) = $sig->( @_ );
  assert ( not $swap );    # test if operands have been swapped
  $s2->isa( TStatusDef )
    ? goto &$add_status_def
    : goto &$add_status_item
}

use overload
  '+' => \&add,
  fallback => 1;

1

__END__

=pod

=head1 NAME

TUI::Menus::StatusDef - status line definition entry

=head1 SYNOPSIS

  use TUI::Menus;

  my $def = new_TStatusDef(
    0,
    0xFFFF,
    $items
  );

=head1 DESCRIPTION

C<TStatusDef> represents a single definition entry used to describe the
contents of a TUI::Vision status line. Each definition associates a range of
help context identifiers with a list of status line items.

Multiple C<TStatusDef> objects can be linked together to form a definition
chain. At runtime, the status line selects the first definition whose context
range matches the current help context and displays the associated items.

This class is primarily used internally by the status line infrastructure and
is rarely manipulated directly by application code.

C<TStatusDef> supports chaining through operator overloading. Multiple status
definitions can be combined using the C<+> operator to form a definition list.
The resulting structure is evaluated sequentially to determine the active
status line entries.

=head1 ATTRIBUTES

The following attributes describe the definition entry. Optional attributes
may be omitted entirely.

=over

=item min

Lower bound of the help context range (I<PositiveOrZeroInt>).

=item max

Upper bound of the help context range (I<PositiveOrZeroInt>).

=item items

Optional reference to a list of status line items (I<TStatusItem>).

=item next

Optional reference to the next C<TStatusDef> in the definition chain.

=back

=head1 CONSTRUCTOR

=head2 new

  my $def = TStatusDef->new(
    min   => $min,
    max   => $max,
    items => $items,
    next  => $next
  );

Creates a new status definition entry.

=over

=item min

Minimum help context value.

=item max

Maximum help context value.

=item items

Optional list of status line items.

=item next

Optional link to the next definition entry.

=back

=head2 new_TStatusDef

  my $def = new_TStatusDef($min, $max, | $items, | $next);

Factory-style constructor using positional arguments.

The C<$items> and C<$next> parameters are optional and may be omitted entirely.
This constructor is provided for compatibility with traditional Turbo Vision
construction patterns.

=head1 METHODS

=head2 add

  my $chain = add($left, $right);
  my $chain = add($left, $right, $swap);

Combines two status definition chains into a single linked list. When C<$swap>
is true, the order of the operands is reversed.

Implements the C<+> operator for chaining status definitions.

This allows multiple C<TStatusDef> objects to be combined into a single
definition list using the C<+> operator.

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
