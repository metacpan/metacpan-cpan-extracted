package TUI::Views::View::Write;
# ABSTRACT: TView write member functions.

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Scalar::Util qw( weaken );

use TUI::Drivers::HardwareInfo;
use TUI::Drivers::HWMouse;
use TUI::Drivers::Screen;
use TUI::Views::Const qw(
  sfVisible
  sfShadow
);
use TUI::Views::View;

# import global variables
use vars qw(
  $shadowSize
  $shadowAttr
  $screenBuffer
);
{
  no strict 'refs';
  *shadowSize   = \${ TView . '::shadowSize' };
  *shadowAttr   = \${ TView . '::shadowAttr' };
  *screenBuffer = \${ TScreen . '::screenBuffer' };
}

use constant HIDEMOUSE => 0;

my $X       = 0;
my $Y       = 0;
my $Count   = 0;
my $wOffset = 0;
my $Buffer  = undef;
my $Target  = undef;
my $edx     = 0;
my $esi     = 0;

use subs qw(
  L0
  L10
  L20
  L30
  L40
  L50
  copyShort
  copyShort2CharInfo
  applyShadow
  reverseAttribute
);

sub L0 {
  my ( $dest, $x, $y, $count, $b ) = @_;
  $X       = $x;
  $Y       = $y;
  $Count   = $count;
  weaken( $Buffer = $b );
  $wOffset = $X;
  $Count  += $X;
  $edx     = 0;

  if ( 0 <= $Y && $Y < $dest->{size}{y} ) {
    $X = 0
      if $X < 0;
    $Count = $dest->{size}{x}
      if $Count > $dest->{size}{x};
    L10( $dest )
      if $X < $Count;
  }
  return;
} #/ sub L0

sub L10 {
  my ( $dest ) = @_;
  my $owner = $dest->{owner};
  if ( ( $dest->{state} & sfVisible ) && $owner ) {
    weaken( $Target = $dest );
    $Y       += $dest->{origin}{y};
    $X       += $dest->{origin}{x};
    $Count   += $dest->{origin}{x};
    $wOffset += $dest->{origin}{x};
    if ( $owner->{clip}{a}{y} <= $Y && $Y < $owner->{clip}{b}{y} ) {
      $X = $owner->{clip}{a}{x}
        if $X < $owner->{clip}{a}{x};
      $Count = $owner->{clip}{b}{x}
        if $Count > $owner->{clip}{b}{x};
      L20( $owner->{last} )
        if $X < $Count;
    }
  } #/ if ( ( $dest->{state} ...))
  return;
} #/ sub L10

sub L20 {
  my ( $dest ) = @_;
  my $next = $dest->{next};
  if ( $next == $Target ) {
    L40( $next );
  }
  else {
    if ( ( $next->{state} & sfVisible ) && $next->{origin}{y} <= $Y ) {
      { # do
        $esi = $next->{origin}{y} + $next->{size}{y};
        if ( $Y < $esi ) {
          $esi = $next->{origin}{x};
          if ( $X < $esi ) {
            if ( $Count > $esi ) {
              L30( $next );
            }
            else {
              last;
            }
          }
          $esi += $next->{size}{x};
          if ( $X < $esi ) {
            if ( $Count > $esi ) {
              $X = $esi;
            }
            else {
              return;
            }
          }
          if ( ( $next->{state} & sfShadow )
            && $next->{origin}{y} + $shadowSize->{y} <= $Y )
          {
            $esi += $shadowSize->{x};
          }
          else {
            last;
          }
        } #/ if ( $Y < $esi )
        elsif ( ( $next->{state} & sfShadow ) 
          && $Y < $esi + $shadowSize->{y}
        ) {
          $esi = $next->{origin}{x} + $shadowSize->{x};
          if ( $X < $esi ) {
            if ( $Count > $esi ) {
              L30( $next );
            }
            else {
              last;
            }
          }
          $esi += $next->{size}{x};
        } #/ elsif ( ( $next->{state} ...))
        else {
          last;
        }
        if ( $X < $esi ) {
          $edx++;
          if ( $Count > $esi ) {
            L30( $next );
            $edx--;
          }
        }
      } # while ( 0 ); 
    } #/ if ( ( $next->{state} ...))
    L20( $next );
  } #/ else [ if ( $next == ...)]
  return;
} #/ sub L20

sub L30 {
  my ( $dest ) = @_;
  my $_Target  = $Target;
  my $_wOffset = $wOffset;
  my $_esi     = $esi;
  my $_edx     = $edx;
  my $_count   = $Count;
  my $_y       = $Y;
  $Count = $esi;

  L20( $dest );

  $Y       = $_y;
  $Count   = $_count;
  $edx     = $_edx;
  $esi     = $_esi;
  $wOffset = $_wOffset;
  weaken( $Target = $_Target );
  $X       = $esi;
  return;
} #/ sub L30

sub L40 {
  my ( $dest ) = @_;
  my $owner = $dest->{owner};
  if ( $owner->{buffer} ) {
    no warnings 'uninitialized';
    if ( $owner->{buffer} != $screenBuffer ) {
      L50( $owner );
    }
    else {
      THWMouse->hide() if HIDEMOUSE;
      L50( $owner );
      THWMouse->show() if HIDEMOUSE;
    }
  } #/ if ( $owner->{buffer} )
  L10( $owner )
    if $owner->{lockFlag} == 0;
  return;
} #/ sub L40

sub L50 {
  my ( $owner ) = @_;
  alias: my $dst = do {
    my ( $a, $b ) = ( $Y * $owner->{size}{x} + $X, $#{ $owner->{buffer} } );
    sub { \@_ }->( @{ $owner->{buffer} }[ $a .. $b ] );
  };
  alias: my $src = do {
    my ( $a, $b ) = ( $X - $wOffset, $#$Buffer );
    sub { \@_ }->( @$Buffer[ $a .. $b ] );
  };
  no warnings 'uninitialized';
  if ( $owner->{buffer} != $screenBuffer ) {
    copyShort( $dst, $src );
  }
  else {
    copyShort2CharInfo( $dst, $src );
    THardwareInfo->screenWrite( $X, $Y, $dst, $Count - $X );
  }
  return;
} #/ sub L50

# On Windows and DOS, Turbo Vision stores a byte of text and a byte of
# attributes for every cell. On Windows, all TGroup buffers follow this scheme, 
# with the exception of the top one, which corresponds to the Win32 console API.

sub copyShort {
  my ( $dst, $src ) = @_;
  if ( $edx == 0 ) {
    my $n = $Count - $X;
    @$dst[ 0 .. $n - 1 ] = @$src[ 0 .. $n - 1 ];
  }
  else {
    for ( my $i = 0 ; $i < $Count - $X ; ++$i ) {
      my ( $c, $color ) = unpack 'CC' => pack 'v'  => $src->[$i];
      $dst->[$i]        = unpack 'v'  => pack 'CC' => $c, applyShadow( $color );
    }
  }
  return;
} #/ sub copyShort

sub copyShort2CharInfo {
  my ( $dst, $src ) = @_;
  my $i;
  if ( $edx == 0 ) {
    # Expand character/attribute pair
    my $n = $Count - $X;
    @$dst[ 0 .. 2 * $n - 1 ] = unpack 'C*' => pack "v*" => @$src[ 0 .. $n - 1 ];
  }
  else {
    # Mix in shadow attribute
    for ( $i = 0 ; $i < $Count - $X ; ++$i ) {
      my ( $c, $color ) = unpack 'CC' => pack 'v' => $src->[$i];
      splice( @$dst, 2 * $i, 2, $c, applyShadow( $color ) );
    }
  }
  return;
} #/ sub copyShort2CharInfo

sub applyShadow {
  my ( $attr ) = @_;
  my $shadowAttrInv = reverseAttribute( $shadowAttr );
  return $attr
    if $attr == $shadowAttr 
    || $attr == $shadowAttrInv;
  return $attr & 0xf0
    ? $shadowAttr
    : $shadowAttrInv;
}

sub reverseAttribute {
  my ( $attr ) = @_;
  return ( ( $attr & 0x0f ) << 4 ) | ( ( $attr & 0xf0 ) >> 4 );
}

1

__END__

=pod

=head1 NAME

TUI::Views::View::Write - TView write member functions.

=head1 DESCRIPTION

TView write member functions.

The content was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT license.

=head1 SEE ALSO

I<tvwrite.asm>, I<tvwrite.cpp>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
