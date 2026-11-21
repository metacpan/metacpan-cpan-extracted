package TUI::Gadgets::CalendarView;
# ABSTRACT: view showing a month calendar

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TCalendarView
  new_TCalendarView
);

use TUI::toolkit;
use TUI::toolkit::Types qw( 
  :is
  :types
);

use TUI::Drivers::Const qw(
  :evXXXX
  kbDown
  kbUp
);
use TUI::Drivers::Event;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  ofSelectable
  sfSelected
);
use TUI::Views::DrawBuffer;
use TUI::Views::View;

sub TCalendarView() { __PACKAGE__ }
sub name() { 'TCalendarView' }
sub new_TCalendarView { __PACKAGE__->from(@_) }

extends TView;

my @monthNames = (
  '',
  qw(
    January February March April May June
    July August September October November December
  ),
);

my @daysInMonth = ( 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

# private attributes
has month    => ( is => 'bare' );
has year     => ( is => 'bare' );
has curDay   => ( is => 'bare' );
has curMonth => ( is => 'bare' );
has curYear  => ( is => 'bare' );

# private methods (anonymous subs, as in TEventViewer)
my ( $dayOfWeek, $nextMonth, $prevMonth );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );

  $self->{options}   |= ofSelectable;
  $self->{eventMask} |= evMouseAuto;

  my ( $day, $mon, $year ) = ( localtime )[ 3, 4, 5 ];
  $self->{year}     = $self->{curYear}  = $year + 1900;
  $self->{month}    = $self->{curMonth} = $mon + 1;
  $self->{curDay}   = $day;

  $self->drawView();
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  if ( $self->{state} & sfSelected ) {
    SWITCH: for ( $event->{what} ) {
      ( evMouse & $_ ) and do {
        my $point = $self->makeLocal( $event->{mouse}{where} );
        ( $point->{x} == 15 && $point->{y} == 0 ) and do {
          $nextMonth->( $self );
          $self->drawView();
          last;
        };
        ( $point->{x} == 18 && $point->{y} == 0 ) and do {
          $prevMonth->( $self );
          $self->drawView();
          last;
        };
        last;
      };

      evKeyboard == $_ and do {
        my $keyCode = $event->{keyDown}{keyCode};
        my $char    = $keyCode & 0xff;
        ( $char == ord( '+' ) || $keyCode == kbDown ) and $nextMonth->( $self );
        ( $char == ord( '-' ) || $keyCode == kbUp )   and $prevMonth->( $self );
        $self->drawView();
        last;
      };
    } #/ SWITCH: for ( $event->{what} )
  }
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $color     = $self->getColor( 6 );
  my $boldColor = $self->getColor( 7 );
  my $month     = $self->{month};
  my $year      = $self->{year};
  my $buf       = TDrawBuffer->new();

  my $current = 1 - $dayOfWeek->( 1, $month, $year );
  my $days    = $daysInMonth[ $month ]
    + ( ( $year % 4 == 0 && $month == 2 ) ? 1 : 0 );

  $buf->moveChar( 0, ' ', $color, 22 );
  $buf->moveStr( 0,
    sprintf( '%9s %4d %s  %s ', 
      $monthNames[ $month ], $year, chr( 30 ), chr( 31 ) ),
    $color );
  $self->writeLine( 0, 0, 22, 1, $buf );

  $buf->moveChar( 0, ' ', $color, 22 );
  $buf->moveStr( 0, 'Su Mo Tu We Th Fr Sa', $color );
  $self->writeLine( 0, 1, 22, 1, $buf );

  for my $i ( 1 .. 6 ) {
    $buf->moveChar( 0, ' ', $color, 22 );
    for my $j ( 0 .. 6 ) {
      if ( $current < 1 || $current > $days ) {
        $buf->moveStr( $j * 3, '   ', $color );
      }
      else {
        my $isToday = $year == $self->{curYear}
          && $month == $self->{curMonth}
          && $current == $self->{curDay};
        $buf->moveStr( $j * 3, sprintf( '%2d', $current ),
          $isToday ? $boldColor : $color );
      }
      $current++;
    }
    $self->writeLine( 0, $i + 1, 22, 1, $buf );
  }
  return;
}

$dayOfWeek = sub {    # $dw ($day, $month, $year)
  my ( $day, $month, $year ) = @_;
  assert ( @_ == 3 );
  assert ( is_Int $day );
  assert ( is_Int $month );
  assert ( is_Int $year );
  if ( $month < 3 ) {
    $month += 10;
    --$year;
  }
  else {
    $month -= 2;
  }
  my $century = int( $year / 100 );
  my $yr      = $year % 100;
  return ( int( ( 26 * $month - 2 ) / 10 ) + $day + $yr
    + int( $yr / 4 ) + int( $century / 4 ) - 2 * $century ) % 7;
};

$nextMonth = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( ++$self->{month} > 12 ) {
    ++$self->{year};
    $self->{month} = 1;
  }
  return;
};

$prevMonth = sub {    # void ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  if ( --$self->{month} < 1 ) {
    --$self->{year};
    $self->{month} = 12;
  }
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
    $self->{month},
    $self->{year},
    $self->{curDay},
    $self->{curMonth},
    $self->{curYear},
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
  $self->{month}    = $is->get();
  $self->{year}     = $is->get();
  $self->{curDay}   = $is->get();
  $self->{curMonth} = $is->get();
  $self->{curYear}  = $is->get();
  return $self;
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::CalendarView - view showing a month calendar

=head1 HIERARCHY

  TObject
    TView
      TCalendarView

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  my $calendar = TCalendarView->new( 
    bounds => TRect->new( ax => 2, ay => 2, bx => 24, by => 10 )
  );
  $window->insert( $calendar );

=head1 DESCRIPTION

C<TCalendarView> shows a calendar page for one month. The first line shows the
month name and the year, followed by the weekday header and up to six weeks.
The current day of the system clock is drawn in the bold color of the palette.

The view is selectable. It changes the month with the C<+> and C<-> keys, the
cursor keys C<Down> and C<Up>, and by clicking the arrows in the header line.

=head1 CONSTRUCTOR

=head2 new

  my $calendar = TCalendarView->new( bounds => $bounds );

Creates a calendar for the current month of the system clock.

=head2 new_TCalendarView

  my $calendar = new_TCalendarView( $bounds );

Factory-style constructor using a positional bounds argument.

=head1 METHODS

=head2 draw

  $calendar->draw();

Draws the month, the weekday header and the days of the month.

=head2 handleEvent

  $calendar->handleEvent( $event );

Changes the displayed month for mouse clicks on the header arrows and for the
keys C<+>, C<->, C<Down> and C<Up>, while the view is selected.

=head1 SEE ALSO

L<TCalendarWindow|TUI::Gadgets::CalendarWindow>,
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
