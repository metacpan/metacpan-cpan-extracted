package TUI::Gadgets::CalcDisplay;
# ABSTRACT: display view of the calculator gadget

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TCalcDisplay
  new_TCalcDisplay
);

use TUI::toolkit;
use TUI::toolkit::Types qw( 
  :is
  :types
);

use TUI::Drivers::Const qw( :evXXXX );
use TUI::Drivers::Event;
use TUI::Gadgets::Const qw(
  cmCalcButton
  cpCalcPalette
);
use TUI::Objects::Rect;
use TUI::Views::Const qw( ofSelectable );
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TCalcDisplay() { __PACKAGE__ }
sub name() { 'TCalcDisplay' }
sub new_TCalcDisplay { __PACKAGE__->from(@_) }

extends TView;

# TCalcState
use constant {
  csFirst => 1,
  csValid => 2,
  csError => 3,
};

# length (width) of the calculator display
use constant {
  DISPLAYLEN => 25,
};

# private attributes
has status  => ( is => 'bare' );
has number  => ( is => 'bare' );
has sign    => ( is => 'bare' );
has operate => ( is => 'bare' );
has operand => ( is => 'bare' );

# private methods (anonymous subs, as in TEventViewer)
my ( $calcKey, $checkFirst, $setDisplay, $clear, $error, $getDisplay );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{options}  |= ofSelectable;
  $self->{eventMask} = evKeyboard | evBroadcast;
  $self->$clear();
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpCalcPalette,
    size => length( cpCalcPalette ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  SWITCH: for ( $event->{what} ) {
    evKeyboard == $_ and do {
      $self->$calcKey( chr( $event->{keyDown}{charScan}{charCode} ) );
      $self->clearEvent( $event );
      last;
    };
    evBroadcast == $_ and do {
      if ( $event->{message}{command} == cmCalcButton ) {
        $self->$calcKey( substr( $event->{message}{infoPtr}{title}, 0, 1 ) );
        $self->clearEvent( $event );
      }
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $color = $self->getColor( 1 );
  my $width = $self->{size}{x};
  my $i     = $width - length( $self->{number} ) - 2;
  my $buf   = TDrawBuffer->new();

  $buf->moveChar( 0, ' ', $color, $width );
  $buf->moveChar( $i, $self->{sign}, $color, 1 );
  $buf->moveStr( $i + 1, $self->{number}, $color );
  $self->writeLine( 0, 0, $width, 1, $buf );
  return;
}

$error = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  $self->{status} = csError;
  $self->{number} = 'Error';
  $self->{sign}   = ' ';
  return;
};

$clear = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  $self->{status}  = csFirst;
  $self->{number}  = '0';
  $self->{sign}    = ' ';
  $self->{operate} = '=';
  return;
};

$setDisplay = sub {    # void ($r)
  my ( $self, $r ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Num $r );
  my $str;
  if ( $r < 0.0 ) {
    $self->{sign} = '-';
    $str = sprintf( '%g', -$r );
  }
  else {
    $self->{sign} = ' ';
    $str = sprintf( '%g', $r );
  }

  my $len = length( $str ) - 1;    # Minus one so we can use as an index.

  if ( $len > DISPLAYLEN ) {
    $self->$error();
  }
  else {
    $self->{number} = $str;
  }
  return;
};

$checkFirst = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( $self->{status} == csFirst ) {
    $self->{status} = csValid;
    $self->{number} = '0';
    $self->{sign}   = ' ';
  }
  return;
};

$getDisplay = sub {    # $num ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  no warnings 'numeric';
  return 0+ $self->{number};
};

$calcKey = sub {    # void ($key)
  my ( $self, $key ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Str $key );

  $key =~ tr/a-z/A-Z/;
  if ( $self->{status} == csError && $key ne 'C' ) {
    $key = ' ';
  }

  SWITCH: for ( $key ) {
    /\A[0-9]\z/ and do {
      $self->$checkFirst();
      if ( length( $self->{number} ) < 15 ) {    # 15 is max visible length
        $self->{number} = '' if $self->{number} eq '0';
        $self->{number} .= $_;
      }
      last;
    };

    '.' eq $_ and do {
      $self->$checkFirst();
      if ( index( $self->{number}, '.' ) < 0 ) {
        $self->{number} .= '.';
      }
      last;
    };

    /\A[\x08\x1B]\z/ and do {    # backspace and escape
      $self->$checkFirst();
      if ( length( $self->{number} ) == 1 ) {
        $self->{number} = '0';
      }
      else {
        chop $self->{number};
      }
      last;
    };

    /\A[_\xF1]\z/ and do {    # underscore and +/- character
      $self->{sign} = $self->{sign} eq ' ' ? '-' : ' ';
      last;
    };

    /\A[-+*\/=%\r]\z/ and do {
      if ( $self->{status} == csValid ) {
        $self->{status} = csFirst;
        my $r = $self->$getDisplay() * ( $self->{sign} eq '-' ? -1.0 : 1.0 );
        if ( $key eq '%' ) {
          if ( $self->{operate} eq '+' || $self->{operate} eq '-' ) {
            $r = ( $self->{operand} * $r ) / 100;
          }
          else {
            $r /= 100;
          }
        }

        SWITCH: for ( $self->{operate} ) {
          '+' eq $_ and do {
            $self->$setDisplay( $self->{operand} + $r );
            last;
          };
          '-' eq $_ and do {
            $self->$setDisplay( $self->{operand} - $r );
            last;
          };
          '*' eq $_ and do {
            $self->$setDisplay( $self->{operand} * $r );
            last;
          };
          '/' eq $_ and do {
            if ( $r == 0 ) {
              $self->$error();
            }
            else {
              $self->$setDisplay( $self->{operand} / $r );
            }
            last;
          };
        } #/ SWITCH: for ( $self->{operate} )
      }
      $self->{operate} = $key;
      $self->{operand} = $self->$getDisplay() 
        * ( $self->{sign} eq '-' ? -1.0 : 1.0 );
      last;
    };

    /\AC\z/ and do {
      $self->$clear();
      last;
    };
  } #/ SWITCH: for ( $key )

  $self->drawView();
  return;
};

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put(
    $self->{status},
    $self->{number},
    $self->{sign},
    $self->{operate},
    $self->{operand},
  );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  $self->{status}  = $is->get();
  $self->{number}  = $is->get();
  $self->{sign}    = $is->get();
  $self->{operate} = $is->get();
  $self->{operand} = $is->get();
  return $self;
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::CalcDisplay - display view of the calculator gadget

=head1 HIERARCHY

  TObject
    TView
      TCalcDisplay

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  my $display = TCalcDisplay->new(
    bounds => TRect->new( ax => 3, ay => 2, bx => 21, by => 3 ),
  );
  $dialog->insert( $display );

=head1 DESCRIPTION

C<TCalcDisplay> is the display of the L<TCalculator|TUI::Gadgets::Calculator>
gadget. It shows the number currently entered or calculated, right-aligned,
with a sign column in front of it.

The view accepts keyboard input and the C<cmCalcButton> broadcasts of the
calculator buttons. It understands the digits, the decimal point, backspace
(C<BS> and C<ESC>), the sign toggle (C<_> and C<+/-> character), the
operators C<+ - * / %>, C<=> and C<Enter>, and C<C> to clear the display.
Division by zero shows C<Error> until the next C<C>.

Results are formatted like the C++ C<ostream> output of a C<double>, that is
with six significant digits.

=head1 CONSTRUCTOR

=head2 new

  my $display = TCalcDisplay->new( bounds => $bounds );

Creates a new display showing C<0>. The view is selectable and receives
keyboard and broadcast events.

=head2 new_TCalcDisplay

  my $display = new_TCalcDisplay( $bounds );

Factory-style constructor using a positional bounds argument.

=head1 METHODS

=head2 draw

  $display->draw();

Draws the sign and the number right-aligned in the view.

=head2 getPalette

  my $palette = $display->getPalette();

Returns the palette of the view.

=head2 handleEvent

  $display->handleEvent( $event );

Processes keyboard events and C<cmCalcButton> broadcasts.

=head1 SEE ALSO

L<TCalculator|TUI::Gadgets::Calculator>,
L<TView|TUI::Views::View>

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
