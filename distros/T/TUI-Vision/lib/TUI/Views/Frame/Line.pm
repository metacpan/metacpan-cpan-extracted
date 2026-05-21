package TUI::Views::Frame::Line;
# ABSTRACT: TFrame frameLine member function.

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use PerlX::Assert::PP;
use List::Util qw( min max );
use TUI::toolkit::Types qw( :is );

use TUI::Views::Const qw(
  cpFrame
  ofFramed
  sfVisible
);
require TUI::Views::Frame;

use vars qw( 
  $initFrame
  $frameChars
);
{
  *initFrame = \$TUI::Views::Frame::initFrame;
  *frameChars = \$TUI::Views::Frame::frameChars;
}

sub TUI::Views::Frame::frameLine {
  my ( $self, $frameBuf, $y, $n, $color ) = @_;
  assert ( @_ == 5 );
  assert ( is_Object $self );
  assert ( is_ArrayLike $frameBuf );
  assert ( is_Int $y );
  assert ( is_Int $n );
  assert ( is_PositiveOrZeroInt $color );

  my @FrameMask = ( ord substr( $initFrame, $n + 1, 1 ) ) x $self->{size}{x};
  $FrameMask[0] = ord substr( $initFrame, $n, 1 );
  $FrameMask[$self->{size}{x} - 1] = ord substr( $initFrame, $n + 2, 1 );

  my $v = $self->{owner}{last}{next};
  for ( ; $v != $self ; $v = $v->{next} ) {
    if ( ( $v->{options} & ofFramed ) && ( $v->{state} & sfVisible ) ) {
      my $mask = 0;
      if ( $y < $v->{origin}{y} ) {
        if ( $y == $v->{origin}{y} - 1 ) {
          $mask = 0x0A06;
        }
      }
      elsif ( $y < $v->{origin}{y} + $v->{size}{y} ) {
        $mask = 0x0005;
      }
      elsif ( $y == $v->{origin}{y} + $v->{size}{y} ) {
        $mask = 0x0A03;
      }

      if ( $mask ) {
        my $start = max( $v->{origin}{x}, 1 );
        my $end = min( $v->{origin}{x} + $v->{size}{x}, $self->{size}{x} - 1 );
        if ( $start < $end ) {
          my $maskLow  = $mask & 0x00FF;
          my $maskHigh = ( $mask & 0xFF00 ) >> 8;
          $FrameMask[$start - 1] |= $maskLow;
          $FrameMask[$end] |= $maskLow ^ $maskHigh;
          if ( $maskLow ) {
            for my $x ($start .. $end - 1) {
              $FrameMask[$x] |= $maskHigh;
            }
          }
        } #/ if ( $start < $end )
      } #/ if ( $mask )
    } #/ if ( ( $v->{options} &...))
  } #/ for ( ; $v != $self ; $v...)

  for my $x ( 0 .. $self->{size}{x} -1 ) {
    $frameBuf->putChar( $x, substr( $frameChars, $FrameMask[$x], 1 ) );
    $frameBuf->putAttribute( $x, $color );
  }
} #/ sub TUI::Views::Frame::frameLine

1

__END__

=pod

=head1 NAME

TUI::Views::Frame::Line - TFrame frameLine member function.

=head1 DESCRIPTION

TFrame frameLine member functions.

The content was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT license.

=head1 SEE ALSO

I<framelin.asm>, I<framelin.cpp>

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
