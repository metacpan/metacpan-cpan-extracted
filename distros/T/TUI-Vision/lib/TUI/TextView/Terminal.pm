package TUI::TextView::Terminal;
# ABSTRACT: TTerminal is a simple text view class

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TTerminal
  new_TTerminal
);

require bytes;
use List::Util qw( min max );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Views::Const qw(
  gfGrowHiX
  gfGrowHiY
  maxViewWidth
);
use TUI::Views::DrawBuffer;
use TUI::TextView::TextDevice;

sub TTerminal() { __PACKAGE__ }
sub name() { 'TTerminal' }
sub new_TTerminal { __PACKAGE__->from(@_) }

extends TTextDevice;

# protected attributes
has bufSize  => ( is => 'ro' );
has buffer   => ( is => 'ro', default => '' );
has queFront => ( is => 'ro', default => 0 );
has queBack  => ( is => 'ro', default => 0 );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds     => Object,
      hScrollBar => Maybe[Object],     { alias => 'aHScrollBar' },
      vScrollBar => Maybe[Object],     { alias => 'aVScrollBar' },
      bufSize    => PositiveOrZeroInt, { alias => 'aBufSize' },
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
  assert ( is_HashRef $args );
  $self->{growMode} = gfGrowHiX | gfGrowHiY;
  $self->{bufSize}  = min( 32000, $args->{bufSize} );
  $self->{buffer}   = "\0" x $self->{bufSize};
  $self->setLimit( 0, 1 );
  $self->setCursor( 0, 0 );
  $self->showCursor();
  return;
}

sub from {    # $term ($bounds, $aHScrollBar|undef, $aVScrollBar|undef, aBufSize)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object], Maybe[Object], PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1], 
    vScrollBar => $args[2], bufSize => $args[3] );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{buffer} = undef;
  return;
}

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<textview.cpp>
sub do_sputn {    # $num ($s, $count)
  state $sig = signature(
    method => Object,
    pos    => [Str, Int],
  );
  my ( $self, $s, $count ) = $sig->( @_ );
  
  my $screenLines = $self->{limit}{y};
  my $i;

  if ( $count > $self->{bufSize} - 1 ) {
    $s     = bytes::substr( $s, $count - ( $self->{bufSize} - 1 ) );
    $count = $self->{bufSize} - 1;
  }

  $screenLines += ( $s =~ tr/\n// );

  while ( !$self->canInsert( $count ) ) {
    $self->{queBack} = $self->nextLine( $self->{queBack} );
    if ( $screenLines > 1 ) {
      $screenLines--;
    }
  }

  if ( $self->{queFront} + $count >= $self->{bufSize} ) {
    $i = $self->{bufSize} - $self->{queFront};
    bytes::substr(
      $self->{buffer}, $self->{queFront}, $i, 
      bytes::substr( $s, 0, $i )
    );
    bytes::substr(
      $self->{buffer}, 0, $count - $i, 
      bytes::substr( $s, $i, $count - $i )
    );
    $self->{queFront} = $count - $i;
  }
  else {
    bytes::substr(
      $self->{buffer}, $self->{queFront}, $count, 
      bytes::substr( $s, 0, $count )
    );
    $self->{queFront} += $count;
  }

  # drawLock: avoid redundant calls to drawView()
  $self->{drawLock}++;
  $self->setLimit( $self->{limit}{x}, $screenLines );
  $self->scrollTo( 0, $screenLines + 1 );
  $self->{drawLock}--;

  $self->drawView();
  return $count;
} #/ sub do_sputn

sub bufInc {    # void (\$val)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef[Int]],
  );
  my ( $self, $val ) = $sig->( @_ );
  if ( ++$$val >= $self->{bufSize} ) {
    $$val = 0;
  }
  return;
}

sub canInsert {    # $bool ($amount)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $amount ) = $sig->( @_ );

  my $T = ( $self->{queFront} < $self->{queBack} )
        ? ( $self->{queFront} + $amount )
        : ( $self->{queFront} - $self->{bufSize} + $amount );
  return $self->{queBack} > $T;
}

sub calcWidth {    # $width ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  ...
}

# The following subroutine was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<textview.cpp>
sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $b = TDrawBuffer->new();
  my $s;
  my $sLen;
  my ( $x, $y );
  my ( $begLine, $endLine, $linePos );
  my $bottomLine;
  my $color = $self->mapColor( 1 );

  $self->setCursor( -1, -1 );

  $bottomLine = $self->{size}{y} + $self->{delta}{y};
  if ( $self->{limit}{y} > $bottomLine ) {
    $endLine =
      $self->prevLines( $self->{queFront}, $self->{limit}{y} - $bottomLine );
    $self->bufDec( \$endLine );
  }
  else {
    $endLine = $self->{queFront};
  }

  if ( $self->{limit}{y} > $self->{size}{y} ) {
    $y = $self->{size}{y} - 1;
  }
  else {
    for ( $y = $self->{limit}{y} ; $y < $self->{size}{y} ; $y++ ) {
      $self->writeChar( 0, $y, ' ', 1, $self->{size}{x} );
    }
    $y = $self->{limit}{y} - 1;
  }

  for ( ; $y >= 0 ; $y-- ) {
    $x       = 0;
    $begLine = $self->prevLines( $endLine, 1 );
    $linePos = $begLine;

    while ( $linePos != $endLine ) {
      # Processing lines of any length by copying only the characters to be 
      # displayed in $s, assuming that these are < maxViewWidth.
      if ( $endLine >= $linePos ) {
        my $cpyLen = min( $endLine - $linePos, maxViewWidth );
        $s    = substr( $self->{buffer}, $linePos, $cpyLen );
        $sLen = $cpyLen;
      }
      else {
        my $fstCpyLen = min( $self->{bufSize} - $linePos, maxViewWidth );
        my $sndCpyLen = min( $endLine, maxViewWidth - $fstCpyLen );
        $s = substr( $self->{buffer}, $linePos, $fstCpyLen )
           . substr( $self->{buffer}, 0, $sndCpyLen );
        $sLen = $fstCpyLen + $sndCpyLen;
      }

      # Report any overlapping characters at the end
      assert ( $sLen == length $s );
      if ( $linePos >= $self->{bufSize} - $sLen ) {
        $linePos = $sLen - ( $self->{bufSize} - $linePos );
      }
      else {
        $linePos += $sLen;
      }

      $x += do { 
        $b->moveStr( $x, $s, $color );
        length $s;
      };
    } #/ while ( $linePos != $endLine)

    $b->moveChar( $x, ' ', $color, max( $self->{size}{x} - $x, 0 ) );
    $self->writeBuf( 0, $y, $self->{size}{x}, 1, $b );

    # Draw the cursor when this is the last line
    if ( $endLine == $self->{queFront} ) {
      $self->setCursor( $x, $y );
    }
    $endLine = $begLine;
    $self->bufDec( \$endLine );
  } #/ for ( ; $y >= 0 ; $y-- )
  return;
} #/ sub draw

sub nextLine {    # $offset ($pos)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $pos ) = $sig->( @_ );

  if ( $pos != $self->{queFront} ) {
    while ( substr( $self->{buffer}, $pos, 1 ) ne "\n"
      && $pos != $self->{queFront}
    ) {
      $self->bufInc( \$pos );
    }
    if ( $pos != $self->{queFront} ) {
      $self->bufInc( \$pos );
    }
  }
  return $pos;
}

# The following two subroutines was taken from the framework
# "A modern port of Turbo Vision 2.0", which is licensed under MIT licence.
#
# Copyright 2019-2021 by magiblot <magiblot@hotmail.com>
#
# I<ttprvlns.cpp>
my $findLfBackwards = sub {    # $bool ($buffer, $pos, $count)
  my ( $buffer, $pos, $count ) = @_;
  assert ( @_ == 3 );
  assert ( is_Str $buffer );
  assert ( is_PositiveOrZeroInt $pos );
  assert ( is_Int $count );
  alias: for $pos ( $_[1] ) {
  # Pre: count >= 1.
  # Post: 'pos' points to the last checked character.
  ++$pos;
  do {
    return true 
      if substr( $buffer, --$pos, 1 ) eq "\n";
  } while ( --$count > 0 );
  return false;
  } #/ alias: for my $pos ( $_[1] )
};

sub prevLines {    # $offset ($pos, $lines)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $pos, $lines ) = $sig->( @_ );

  if ( $lines > 0 && $pos != $self->{queBack} ) {
    do {
      return $self->{queBack} 
          if $pos == $self->{queBack};
      $self->bufDec( \$pos );
      my $count = ( $pos >= $self->{queBack}
                  ? $pos - $self->{queBack}
                  : $pos ) + 1;
      --$lines if &$findLfBackwards( $self->{buffer}, $pos, $count );
    } while ( $lines > 0 );
    $self->bufInc( \$pos );
  } #/ if ( $lines > 0 && $pos...)
  return $pos;
}

sub queEmpty {    # $bool ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{queBack} == $self->{queFront};
}

sub bufDec {    # void ($val)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef[Int]],
  );
  my ( $self, $val ) = $sig->( @_ );
  if ( $$val == 0 ) {
    $$val = $self->{bufSize} - 1;
  }
  else {
    $$val--;
  }
  return;
}

1

__END__

=pod

=head1 NAME

TUI::TextView::Terminal - scrollable terminal-style text output view

=head1 HIERARCHY

  TObject
    TView
      TScroller
        TTextDevice
          TTerminal

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Views;
  use TUI::TextView;

  my $bounds = TRect->new( ax => 0, ay => 0, bx => 60, by => 20 );
  my $hBar   = TScrollBar->new(
    bounds => TRect->new( ax => 0, ay => 19, bx => 59, by => 20 )
  );
  my $vBar   = TScrollBar->new(
    bounds => TRect->new( ax => 59, ay => 0, bx => 60, by => 19 )
  );

  my $term = TTerminal->new(
    bounds     => $bounds,
    hScrollBar => $hBar,
    vScrollBar => $vBar,
    bufSize    => 4096,
  );

  tie *TERM, TTerminal => (
    bounds     => $bounds,
    hScrollBar => $hBar,
    vScrollBar => $vBar,
    bufSize    => 4096,
  );

  print TERM "connected to remote host\n";
  syswrite TERM, "login successful\n";
  close TERM;

=head1 DESCRIPTION

C<TTerminal> implements a simple, scrollable, write-only text view that behaves
like a terminal output window. Text written to the terminal is stored in an
internal circular buffer and displayed in a scrollable view with optional
horizontal and vertical scroll bars.

The terminal buffer automatically wraps around when it reaches its configured
size, allowing older data to be discarded as new output is appended. Line
boundaries are detected using line feed characters, which makes the terminal
suitable for log output, console-style views, and similar streaming text use
cases.

C<TTerminal> extends C<TTextDevice> and is commonly used as a rendering target
for redirected text output. Reading from the buffer is not supported by
default and must be implemented explicitly by subclasses if required.

=head2 Commonly Used Features

In application code, C<TTerminal> is usually initialized once and then written
through the text-device interface (C<print>, C<printf>, C<say>, C<syswrite>).
When explicit capacity checks are needed before larger writes, C<canInsert>
provides the primary guard.

=head1 ATTRIBUTES

The following attributes are exposed as read-only accessors and are intended
for internal use by the terminal implementation. They reflect the current state
of the circular buffer and should not be modified directly.

=over

=item bufSize

Read-only size of the internal circular buffer in bytes (I<Int>).  
This value is defined at construction time and does not change.

=item buffer

Read-only reference to the internal buffer storage.  
The buffer is allocated and managed internally by the terminal.

=item queFront

Read-only index pointing to the first byte currently stored in the buffer.

=item queBack

Read-only index pointing to the most recently written byte in the buffer.

=back

=head1 METHODS

=head2 new

  my $term = TTerminal->new(
    bounds     => $bounds,
    hScrollBar => $hBar,
    vScrollBar => $vBar,
    bufSize    => $bufSize
  );

Creates and initializes a new terminal view.

=over

=item bounds

Bounding rectangle of the terminal view (I<TRect>).  
This parameter is required.

=item hScrollBar

Horizontal scroll bar associated with the terminal (I<TScrollBar>).

This parameter must be provided, but its value may be C<undef> if no horizontal
scroll bar is required.

=item vScrollBar

Vertical scroll bar associated with the terminal (I<TScrollBar>).

This parameter must be provided, but its value may be C<undef> if no vertical
scroll bar is required.

=item bufSize

Size of the internal circular buffer in bytes (I<PositiveOrZeroInt>).  
This parameter is required and determines how much text can be retained before
older data is discarded.

=back

=head2 new_TTerminal

  my $term = new_TTerminal($bounds, $aHScrollBar, $aVScrollBar, $aBufSize);

Factory constructor for creating a terminal instance using positional
parameters.

=head2 bufInc

  $self->bufInc(\$val);

Advances a buffer index by one position, wrapping around to the beginning of
the buffer if the end is reached.

=head2 bufDec

  $self->bufDec(\$val);

Moves a buffer index one position backwards, wrapping around to the end of the
buffer if necessary.

=head2 canInsert

  my $bool = $self->canInsert($amount);

Checks whether C<$amount> bytes can be inserted into the buffer without
discarding existing data.

Returns true if sufficient space is available, or false if insertion would
require overwriting older content.

=head2 do_sputn

  my $num = $self->do_sputn($s, $count);

Low-level output routine that writes C<$count> bytes from C<$s> into the
terminal buffer and updates the view. Line feed characters mark the start of
new lines in the scroll buffer.

This method is primarily an internal override point used by the text-device
write path. Application code should normally write through C<print>, C<printf>,
C<say>, or C<syswrite>.

=head2 nextLine

  my $pos = $self->nextLine($pos);

Scans forward from the given buffer position and returns the position of the
next line start.

=head2 prevLines

  my $pos = $self->prevLines($pos, $lines);

Moves backwards from the given buffer position by the specified number of
lines and returns the resulting position.

=head2 queEmpty

  my $bool = $self->queEmpty();

Returns true if the buffer queue is empty, false otherwise.

=head2 draw

  $self->draw();

Renders the contents of the terminal buffer into the view, taking the current
scroll position into account.

=head2 getPalette

  my $palette = $self->getPalette();

Returns the color palette used to draw the terminal view.

=head2 DEMOLISH

  DEMOLISH($in_global_destruction);

Cleans up the terminal instance and releases the internal buffer. This method
corresponds to the Turbo Vision destructor and is normally invoked
automatically.

=head1 SEE ALSO

L<TUI::TextView::TextDevice>, L<TUI::Views::Scroller>

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
