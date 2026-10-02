package TUI::Drivers::AttrPair;
# ABSTRACT: pair of color attributes value type

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TAttrPair
);

use PerlX::Assert::PP;
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TUI::Drivers::ColorAttr;

sub TAttrPair() { __PACKAGE__ }

# macro for coercing a value into a TColorAttr object
my $coerceAttr = sub {
  return ref $_[0] ? $_[0] : TColorAttr->new( bios => $_[0] );
};

# TAttrPair can be used as a 2-element array ([0]: low, [1]: high).
# Instead of the operator '@{}' Perl's internal array reference access is 
# used, since it is resolved at compile time.

sub new {    # $obj (|%args)
  my ( $class, @args ) = @_;
  assert ( $class and !ref $class );

  my ( $lo, $hi );

  # TAttrPair->new()
  if ( !@args ) {
    $lo = TColorAttr->new();
    $hi = TColorAttr->new();
  }

  # TAttrPair->new( bios => Int )
  elsif ( @args == 2 && $args[0] eq 'bios' ) {
    my $bios = $args[1];
    assert ( looks_like_number $bios );
    $lo = TColorAttr->new( bios => $bios );
    $hi = TColorAttr->new( bios => $bios >> 8 );
  }

  # TAttrPair->new( lo => TColorAttr, | hi => TColorAttr )
  elsif ( @args % 2 == 0 ) {
    my %args = @args;
    assert ( blessed $args{lo} or looks_like_number $args{lo} );
    assert ( !exists $args{hi} or defined $args{hi} );

    $lo = ref $args{lo} ? $args{lo}->clone() : $args{lo}->$coerceAttr();
    $hi = exists $args{hi}
        ? ref $args{hi} ? $args{hi}->clone() : $args{hi}->$coerceAttr()
        : TColorAttr->new( bios => 0 );
  }

  else {
    return;
  }

  assert ( blessed $lo and $lo->isa( TColorAttr ) );
  assert ( blessed $hi and $hi->isa( TColorAttr ) );

  return bless [ $lo, $hi ], $class;
} #/ sub new

sub assign {    # void ($other)
  my ( $self, $other ) = @_;
  assert ( blessed $self );
  assert ( blessed $other );
  $self->[0]->assign( $other->[0] );
  $self->[1]->assign( $other->[1] );
  return;
}

sub clone {    # $obj ()
  my ( $self ) = @_;
  assert ( blessed $self );
  my $lo = $self->[0]->clone();
  my $hi = $self->[1]->clone();
  return bless [ $lo, $hi ], ref $self;
}

# Backward-compatibility functions:
#
# Return the corresponding pair of BIOS color attributes. Only works
# properly if both attributes are actually BIOS color attributes:
# see TColorAttr overload '0+'.

sub asBIOS {    # $bios ()
  my ( $self ) = @_;
  assert ( blessed $self );
  return ( $self->[0]->asBIOS & 0xff ) | ( ( $self->[1]->asBIOS & 0xff ) << 8 );
}

# Used to compose attribute pairs in legacy code.

sub rshift {    # $result ($shift)
  my ( $self, $shift ) = @_;
  assert ( blessed $self );
  assert ( looks_like_number $shift );

  # Legacy code may use '>> 8' on an attribute pair to get the higher attribute.
  return TAttrPair->new( lo => $self->[1] )
    if $shift == 8;
  return TAttrPair->new( bios => $self->asBIOS >> $shift );
}

sub setLo {    # $self ($attr)
  my ( $self, $attr ) = @_;
  assert ( blessed $self );
  assert ( blessed $attr or looks_like_number $attr );

  # Legacy code may use '|=' on an attribute pair to set the lower attribute.
  # However, that's only if the lower attribute is equivalent to the BIOS
  # color attribute 0x00. Otherwise, this is just an arithmetic operation.
  $attr = $coerceAttr->( $attr );
  my $lo = $self->[0];
  my $bios = $lo->asBIOS;
  if ( $bios == 0 ) {
    $lo->assign( $attr );
  }
  else {
    $lo->assign( TColor->new( bios => $bios | $attr->asBIOS ) );
  }
  return $self;
}

use overload
  '0+'     => \&asBIOS,
  '>>'     => \&rshift,
  '|='     => \&setLo,
  fallback => 1;

1;

__END__

=head1 NAME

TUI::Drivers::AttrPair - pair of color attributes value type

=head1 SYNOPSIS

  use TUI::Drivers;
  
  my $cNormal = TColorAttr->new( fg => ['#234983'], bg => ['#267232'] );
  my $cHigh   = TColorAttr->new( fg => ['#309283'], bg => ['#127844'] );
  my $attrs   = TAttrPair->new( lo => $cNormal, hi => $cHigh );

  my $b = TDrawBuffer->new();
  $b->moveCStr( 0, "Normal text, ~Highlighted text~", $attrs );

=head1 DESCRIPTION

This module provides C<TAttrPair>, a value type that represents a pair of color 
attributes.

A C<TAttrPair> is a blessed array reference of two 
L<TColorAttr|TUI::Drivers::ColorAttr> elements, conventionally called the 
I<"low"> (index C<0>) and I<"high"> (index C<1>) attribute. Some API functions, 
such as C<< TDrawBuffer->moveCStr >>, use a C<TAttrPair> to pass both a normal 
and a highlighted attribute at once.

=head1 CONSTRUCTOR

=head2 new

Creates a color attribute pair.

With no arguments, both attributes use default colors and no style flags:

  my $attrs = TAttrPair->new();

With a BIOS color attribute pair, the low byte becomes the low attribute and
the high byte becomes the high attribute:

  my $attrs = TAttrPair->new( bios => 0x1e3d );

With explicit low and optional high attributes:

  my $attrs = TAttrPair->new(
    lo => $cNormal,
    hi => $cHigh,
  );

If C<hi> is omitted, it defaults to a BIOS attribute of C<0>. The C<lo> and
C<hi> arguments must be L<TColorAttr|TUI::Drivers::ColorAttr> values, but a 
plain integer is also accepted as a shorthand for a BIOS attribute.

=head1 METHODS

=head2 asBIOS

  my $bios = $self->asBIOS();

Returns a BIOS attribute pair, with the low attribute in the low byte and
the high attribute in the high byte.

=head2 assign

  $self->assign($other);

Assigns the value of another C<TAttrPair> to this one.

=head2 clone

  my $clone = $self->clone();

Returns a new C<TAttrPair> that is a copy of this one.

=head2 rshift

  my $result = $self->rshift($shift);

Shifts the C<asBIOS> value right by C<$shift> bits.

As a special case, shifting by C<8> returns a new C<TAttrPair> whose low
attribute is this pair's high attribute, for compatibility with legacy code
that used C<< >> 8 >> on an attribute pair to extract the higher attribute.

=head2 setLo

  $self->setLo($attr);

Sets the low attribute, for compatibility with legacy code that used
C<< |= >> on an attribute pair to set the lower attribute.

Returns C<$self>.

=head1 OPERATORS

=head2 Numeric conversion

  my $bios = 0+ $attrs;

Returns the C<asBIOS> value of this pair.

=head2 Right shift

  my $result = $attrs >> $shift;

Calls L</rshift>.

=head2 Bitwise-or assignment

  $attrs |= $attr;

Calls L</setLo>.

=head2 Array element access

Being a blessed array reference, the individual attributes can be accessed
and replaced directly with C<< $attrs->[0] >> (low) and C<< $attrs->[1] >>
(high):

  my $lo = $attrs->[0];
  $attrs->[1] = TColorAttr->new( bios => 0x70 );

=head1 SEE ALSO

L<TColorAttr|TUI::Drivers::ColorAttr>

=head1 AUTHORS

=over

=item * magiblot <magiblot@hotmail.com> (original attribute pair design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2026 the L</AUTHORS> listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
