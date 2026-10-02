package TUI::Drivers::ScreenCell;
# ABSTRACT: screen cell value type

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TScreenCell
);

use PerlX::Assert::PP;
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TUI::Drivers::AttrPair;
use TUI::Drivers::ColorAttr;
use TUI::Drivers::ScreenCharacter;

sub TScreenCell() { __PACKAGE__ }

# macro for coercing a value into a TScreenCharacter object
my $coerceChar = sub {
  return ref $_[0] ? $_[0] : TScreenCharacter->new( text => $_[0] );
};

# macro for coercing a value into a TColorAttr object
my $coerceAttr = sub {
  return ref $_[0] ? $_[0] : TColorAttr->new( bios => $_[0] );
};

sub new {    # $cell (|%args)
  my ( $class, @args ) = @_;
  assert ( $class and !ref $class );

  my ( $lo, $hi );

  # TScreenCell->new()
  if ( !@args ) {
    $lo = TScreenCharacter->new();
    $hi = TColorAttr->new();
  }

  # TScreenCell->new( bios => Int )
  elsif ( @args == 2 && $args[0] eq 'bios' ) {
    assert ( looks_like_number $args[1] );
    my $bios = $args[1];
    my ( $ch, $attr ) = unpack 'aC' => pack 'v' => $bios;
    $lo = TScreenCharacter->new( text => $ch );
    $hi = TColorAttr->new( bios => $attr );
  }

  # TScreenCell->new( ch => TScreenCharacter, attr => TColorAttr )
  elsif ( @args % 2 == 0 ) {
    my %args = @args;
    assert ( exists $args{ch} && exists $args{attr} );
    assert ( blessed $args{ch} or !ref $args{ch} && length $args{ch} );
    assert ( blessed $args{attr} or looks_like_number $args{attr} );

    $lo = ref $args{ch}   ? $args{ch}->clone()   : $args{ch}->$coerceChar();
    $hi = ref $args{attr} ? $args{attr}->clone() : $args{attr}->$coerceAttr();
  }

  else {
    return;
  }

  assert ( blessed $lo and $lo->isa( TScreenCharacter ) );
  assert ( blessed $hi and $hi->isa( TColorAttr ) );

  return bless [ $lo, $hi ], $class;
}

sub assign {    # void ($other)
  my ( $self, $other ) = @_;
  assert ( blessed $self );
  assert ( blessed $other );
  $self->[0]->assign( $other->[0] );
  $self->[1]->assign( $other->[1] );
  return;
}

sub clone {    # $cell ()
  my ( $self ) = @_;
  assert ( blessed $self );
  return bless [
    $self->[0]->clone(),
    $self->[1]->clone(),
  ], ref $self;
}

sub character {    # $ch|undef (|$ch)
  my ( $cell, $ch ) = @_;
  assert ( blessed $cell );
  assert ( !defined $ch or blessed $ch or !ref $ch );
  goto SET if @_ > 1;
  GET: {
    return $cell->[0];
  }
  SET: {
    ${ $cell->[0] } = ${ $ch->$coerceChar() };
    return;
  }
}

sub attribute {    # $attr|undef (|$attr)
  my ( $cell, $attr ) = @_;
  assert ( blessed $cell );
  assert ( !defined $attr or blessed $attr or looks_like_number $attr );
  goto SET if @_ > 1;
  GET: {
    return $cell->[1];
  }
  SET: {
    assert ( defined $attr );
    ${ $cell->[1] } = ref $attr eq TAttrPair
                    ? ${ $attr->[0] }    # retrieve the lo value from the pair
                    : ${ $attr->$coerceAttr() };
    return;
  }
}

sub equals {    # $bool ($other)
  my ( $self, $other ) = @_;
  assert ( blessed $self );
  assert ( blessed $other );
  return ref $self eq ref $other
      && ${ $self->[0] } eq ${ $other->[0] }
      && $self->[1]->equals( $other->[1] );
}

use overload
  '==' => \&equals,
  fallback => 1;

1;

=head1 NAME

TUI::Drivers::ScreenCell - screen cell value type

=head1 SYNOPSIS

  use TUI::Drivers;

  my $cell = TScreenCell->new(
    bios => 0x411F,
  );

  $cell = TScreenCell->new(
    ch   => 'A',
    attr => 0x1F,
  );

  $cell->character( 'A' );

  my $attr = $cell->attribute;
  my $ch   = $cell->character;

=head1 DESCRIPTION

C<TScreenCell> stores the character and color attributes associated with
a screen cell.

A screen cell consists of:

=over

=item *

a L<TScreenCharacter|TUI::Drivers::ScreenCharacter> value describing the cell 
contents

=item *

a L<TColorAttr|TUI::Drivers::ColorAttr> value describing the cell attributes

=back

Double-width characters occupy two adjacent screen cells. The first cell
contains the character itself and the second cell contains a wide-character
trail placeholder.

If a double-width character is not followed by a wide-character trail, or
if a wide-character trail is not preceded by a double-width character, the
character is considered to be partially overwritten.

L<TScreenCharacter|TUI::Drivers::ScreenCharacter> is designed to be compatible 
with Borland's I<Turbo Vision> cell structure, and it is therefore trivially 
constructible and copyable via L</assign> and L</clone>. 
                                                                
A zero-initialized TScreenCharacter is valid and represents the text of an 
empty screen cell.

=head1 CONSTRUCTOR

=head2 new

Creates a screen cell.

  my $cell = TScreenCell->new();

Construct a cell using default attributes and an empty character value.

  my $cell = TScreenCell->new( bios => 0x411F );

Construct a cell from a PC text-mode character/attribute word.

  my $cell = TScreenCell->new( ch => $char, attr => $attr );

Construct a cell consisting of a character and an attribute value.

=head1 METHODS

=head2 assign

  $self->assign($other);

Copies the contents of another C<TScreenCell> into the current one.

=head2 attribute

 my $attr = $self->attribute();
 $self->attribute($attr);

Sets the cell attributes or returns the L<TColorAttr|TUI::Drivers::ColorAttr> 
associated with the cell.

=head2 character

 my $ch = $self->character();
 $self->character($ch);

Sets the character stored in the cell or returns the 
L<TScreenCharacter|TUI::Drivers::ScreenCharacter> stored in the cell.

=head2 clone

  my $cell = $self->clone();

Returns a new C<TScreenCell> object that is a copy of the current one.

=head2 equals

 my $bool = $self->equals($other);

Returns true if both screen cells contain identical character and
attribute values.

=head1 OPERATORS

=head2 Numeric equality

  $a == $b

Returns true when C<TScreenCell> values contain identical data.

=head1 SEE ALSO

L<TScreenCharacter|TUI::Drivers::ScreenCharacter>,
L<TColorAttr|TUI::Drivers::ColorAttr>

=head1 AUTHORS

=over

=item * magiblot <magiblot@hotmail.com> (original screen cell design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2026 the L</AUTHORS> listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
