package TUI::Gadgets::CalendarWindow;
# ABSTRACT: window containing a month calendar

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TCalendarWindow
  new_TCalendarWindow
);

use Carp ();
use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  is_Str
  :types
);

use TUI::Gadgets::CalendarView;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  wfGrow
  wfZoom
  wnNoNumber
  wpCyanWindow
);
use TUI::Views::Window;

sub TCalendarWindow() { __PACKAGE__ }
sub name() { 'TCalendarWindow' }
sub new_TCalendarWindow { __PACKAGE__->from(@_) }

extends TWindow;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method       => 1,
    named        => [],
    caller_level => +1,
  );
  my ( $class ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return $class->SUPER::BUILDARGS(
    bounds => TRect->new( ax => 1, ay => 1, bx => 23, by => 11 ),
    title  => 'Calendar',
    number => wnNoNumber,
  );
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );

  $self->{flags}    &= ~( wfZoom | wfGrow );
  $self->{growMode} = 0;
  $self->{palette}  = wpCyanWindow;

  my $r = $self->getExtent();
  $r->grow( -1, -1 );
  $self->insert( TCalendarView->new( bounds => $r ) );
  return;
}

sub from {    # $calendarWindow ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class ) = $sig->( @_ );
  return $class->new();
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new();
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::CalendarWindow - window containing a month calendar

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TCalendarWindow

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  my $window = new_TCalendarWindow();
  $deskTop->insert( $window );

=head1 DESCRIPTION

C<TCalendarWindow> is a fixed-size window titled C<Calendar>. It contains a
L<TCalendarView|TUI::Gadgets::CalendarView> that shows the current month.

The window cannot be zoomed or resized and has no window number.

=head1 CONSTRUCTOR

=head2 new

  my $window = TCalendarWindow->new();

Creates the calendar window with its calendar view.

=head2 new_TCalendarWindow

  my $window = new_TCalendarWindow();

Factory-style constructor without arguments.

=head1 SEE ALSO

L<TCalendarView|TUI::Gadgets::CalendarView>,
L<TWindow|TUI::Views::Window>

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
