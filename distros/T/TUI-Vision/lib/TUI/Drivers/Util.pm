package TUI::Drivers::Util;
# ABSTRACT: defines various utility functions used throughout Drivers

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  ctrlToArrow
  cstrlen
  getAltChar
  getAltCode
  getCtrlChar
  getCtrlCode
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use Devel::StrictMode;
use PerlX::Assert::PP;
use Scalar::Util qw(
  looks_like_number
);

use TUI::Drivers::Const qw(
  /^kbCtrl[A-X]$/
  kbLeft kbRight kbUp  kbDown kbHome
  kbEnd  kbDel   kbIns kbPgUp kbPgDn kbBack
);

my @ctrlCodes = map { $_ & 0xff } (    # lower byte
  kbCtrlS, kbCtrlD, kbCtrlE, kbCtrlX, kbCtrlA,
  kbCtrlF, kbCtrlG, kbCtrlV, kbCtrlR, kbCtrlC, kbCtrlH
);

my @arrowCodes = (
  kbLeft, kbRight, kbUp, kbDown, kbHome,
  kbEnd,  kbDel,   kbIns,kbPgUp, kbPgDn, kbBack
);

if ( STRICT && exists &Internals::SvREADONLY ) {
  map { Internals::SvREADONLY $ctrlCodes[$_]  => 1 } 0 .. $#ctrlCodes;
  map { Internals::SvREADONLY $arrowCodes[$_] => 1 } 0 .. $#arrowCodes;
}

sub ctrlToArrow ($) {    # $keyCode ($keyCode)
  assert ( @_ == 1 );
  my $keyCode = shift;
  assert ( looks_like_number $keyCode );

  for my $i ( 0 .. $#ctrlCodes ) {
    return $arrowCodes[$i]
      if ( $keyCode & 0x00ff ) == $ctrlCodes[$i];
  }
  return $keyCode;
} #/ sub ctrlToArrow

sub cstrlen ($) {    # $len ($s)
  $_[0] =~ tr/~//c;
}

my @altCodes1 = unpack '(a)*', "QWERTYUIOP\0\0\0\0ASDFGHJKL\0\0\0\0\0ZXCVBNM";
my @altCodes2 = unpack '(a)*', "1234567890-=";

if ( STRICT && exists &Internals::SvREADONLY ) {
  map { Internals::SvREADONLY $altCodes1[$_] => 1 } 0 .. $#altCodes1;
  map { Internals::SvREADONLY $altCodes2[$_] => 1 } 0 .. $#altCodes2;
}

sub getAltChar ($) {    # $char ($keyCode)
  assert ( @_ == 1 );
  my $keyCode = shift;
  assert ( looks_like_number $keyCode );
  if ( ( $keyCode & 0xff ) == 0 ) {
    my $tmp = ( $keyCode >> 8 );

    if ( $tmp == 2 ) {
      return "\xF0";    # special case to handle alt-Space
    }
    elsif ( $tmp >= 0x10 && $tmp <= 0x32 ) {
      return $altCodes1[ $tmp - 0x10 ];    # alt-letter
    }
    elsif ( $tmp >= 0x78 && $tmp <= 0x83 ) {
      return $altCodes2[ $tmp - 0x78 ];    # alt-number
    }

  } #/ if ( ( $keyCode & 0xff...))
  return "\0";
} #/ sub getAltChar

sub getAltCode ($) {    # $keyCode ($c)
  assert ( @_ == 1 );
  my $c = shift;
  assert ( defined $c and !ref $c );
  return 0
    unless $c;

  $c = uc( $c );

  return 0x200
    if ord( $c ) == 0xF0;    # special case to handle alt-Space

  for my $i ( 0 .. $#altCodes1 ) {
    return ( $i + 0x10 ) << 8
      if $altCodes1[$i] eq $c;
  }

  for my $i ( 0 .. $#altCodes2 ) {
    return ( $i + 0x78 ) << 8
      if $altCodes2[$i] eq $c;
  }

  return 0;
} #/ sub getAltCode

sub getCtrlChar ($) {    # $char ($keyCode)
  assert ( @_ == 1 );
  my $keyCode = shift;
  assert ( looks_like_number $keyCode );
  return ( $keyCode & 0xff ) != 0
      && ( $keyCode & 0xff ) <= ( ord( 'Z' ) - ord( 'A' ) + 1 )
        ? chr( ( $keyCode & 0xff ) + ord( 'A' ) - 1 )
        : "\0";
}

sub getCtrlCode ($) {    # $keyCode ($ch)
  assert ( @_ == 1 );
  my $ch = shift;
  assert ( defined $ch and !ref $ch );
  return getAltCode( $ch ) | 
    (
      (
        ( $ch ge 'a' && $ch le 'z' )
        ? ( ord( $ch ) & ~0x20 )
        : ord( $ch )
      ) - ord( 'A' ) + 1
    );
} #/ sub getCtrlCode

1

__END__

=pod

=head1 NAME

TUI::Drivers::Util - utility functions for keyboard and event handling

=head1 SYNOPSIS

  use TUI::Drivers::Util qw(
    cstrlen
    ctrlToArrow
    getAltChar
    getAltCode
    getCtrlChar
    getCtrlCode
  );

  my $len = cstrlen($string);
  my $arrow = ctrlToArrow($keyCode);

  my $altCode = getAltCode('X');
  my $altChar = getAltChar($altCode);

  my $ctrlCode = getCtrlCode('C');
  my $ctrlChar = getCtrlChar($ctrlCode);

=head1 DESCRIPTION

C<TUI::Drivers::Util> provides a collection of low-level helper functions used
by the TUI::Vision driver and event system.

The functions in this module operate on key codes and character values and are
used to translate between control, alternate, and normal key representations.
They are intended for internal use by event processing and input handling
code.

This module is purely functional and does not define any objects.

=head2 Commonly Used Features

Typical usage falls into three groups: converting control-key navigation
shortcuts to arrow/navigation key codes via C<ctrlToArrow()>, translating
between Alt key codes and characters via C<getAltCode()>/C<getAltChar()>, and
translating between Ctrl key codes and characters via
C<getCtrlCode()>/C<getCtrlChar()>.

C<cstrlen()> is commonly used when text contains TUI::Vision marker
characters C<~> and a marker-aware length is needed.

=head1 FUNCTIONS

=head2 cstrlen

  my $len = cstrlen($string);

Returns the length of a string up to the first null character.

This function behaves like the C runtime C<strlen> and is useful when working
with strings that may contain embedded null characters.

=head2 ctrlToArrow

  my $keyCode = ctrlToArrow($keyCode);

Maps certain control key codes to their corresponding arrow key codes.

If the key code does not represent a convertible control key, it is returned
unchanged.

=head2 getAltChar

  my $char = getAltChar($keyCode);

Returns the character associated with an Alt-modified key code.

If the key code does not represent an Alt-modified character, the return value
is undefined.

=head2 getAltCode

  my $keyCode = getAltCode($char);

Returns the Alt-modified key code corresponding to the given character.

=head2 getCtrlChar

  my $char = getCtrlChar($keyCode);

Returns the character associated with a Ctrl-modified key code.

=head2 getCtrlCode

  my $keyCode = getCtrlCode($char);

Returns the Ctrl-modified key code corresponding to the given character.

=head1 SEE ALSO

L<TUI::Drivers::Const>,
L<TUI::Drivers::Event>

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

