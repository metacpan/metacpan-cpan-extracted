package TUI::Gadgets::MouseDialog;
# ABSTRACT: dialog for configuring mouse options

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMouseDialog
  new_TMouseDialog
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Dialogs::Const qw(
  bfDefault
  bfNormal
);
use TUI::Dialogs::Button;
use TUI::Dialogs::CheckBoxes;
use TUI::Dialogs::Dialog;
use TUI::Dialogs::Label;
use TUI::Dialogs::StrItem;
use TUI::Drivers::Const qw(
  evBroadcast
  evCommand
);
use TUI::Drivers::EventQueue;
use TUI::Gadgets::ClickTester;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  cmCancel
  cmOK
  cmScrollBarChanged
  ofCentered
  ofSelectable
);
use TUI::Views::ScrollBar;

sub TMouseDialog() { __PACKAGE__ }
sub name() { 'TMouseDialog' }
sub new_TMouseDialog { __PACKAGE__->from(@_) }

extends TDialog;

# import global variables
use vars qw(
  $doubleDelay
); 
{
  *doubleDelay = \$TUI::Drivers::EventQueue::doubleDelay;
}

# private attributes
has mouseScrollBar  => ( is => 'bare' );
has oldDelay        => ( is => 'bare' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [],
    caller_level => +1,
  );
  my ( $class ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return $class->SUPER::BUILDARGS(
    bounds => TRect->new( ax => 0, ay => 0, bx => 34, by => 12 ), 
    title  => "Mouse options", 
  );
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );

  my $r = TRect->new( ax => 3, ay => 4, bx => 30, by => 5 );

  $self->{options} |= ofCentered;

  $self->{mouseScrollBar} = TScrollBar->new( bounds => $r );
  $self->{mouseScrollBar}->setParams( 1, 1, 20, 20, 1 );
  $self->{mouseScrollBar}{options} |= ofSelectable;
  $self->{mouseScrollBar}->setValue( $doubleDelay );
  $self->insert( $self->{mouseScrollBar} );

  $r = TRect->new( ax => 2, ay => 2, bx => 21, by => 3 );
  $self->insert( TLabel->new(
    bounds => $r,
    text   => "~M~ouse double click",
    link   => $self->{mouseScrollBar},
  ));

  $r = TRect->new( ax => 3, ay => 3, bx => 30, by => 4 );
  $self->insert( TClickTester->new(
    bounds => $r,
    text   => "Fast       Medium      Slow",
  ));

  $r = TRect->new( ax => 3, ay => 6, bx => 30, by => 7 );
  $self->insert( TCheckBoxes->new(
    bounds  => $r,
    strings => new_TSItem( "~R~everse mouse buttons", undef ),
  ));
  $self->{oldDelay} = $doubleDelay;

  $r = TRect->new( ax => 9, ay => 9, bx => 19, by => 11 );
  $self->insert( TButton->new( 
    bounds  => $r,
    title   => "O~K~", 
    command => cmOK, 
    flags   => bfDefault,
  ));

  $r = TRect->new( ax => 21, ay => 9, bx => 31, by => 11 );
  $self->insert( TButton->new(
    bounds  => $r,
    title   => "Cancel", 
    command => cmCancel, 
    flags   => bfNormal,
  ));

  $self->selectNext( false );
  return;
}

sub from {    # $obj ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class) = $sig->( @_ );
  return $class->new();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );
  SWITCH: for ( $event->{what} ) {
    evCommand == $_ and do {
      $doubleDelay = $self->{oldDelay}
        if $event->{message}{command} == cmCancel;
      last;
    };
    evBroadcast == $_ and do {
      if ( $event->{message}{command} == cmScrollBarChanged ) {
        $doubleDelay = $self->{mouseScrollBar}{value};
        $self->clearEvent( $event );
      }
      last;
    };
  }
  return;
} #/ sub handleEvent

1

__END__

=pod

=head1 NAME

TUI::Gadgets::MouseDialog - dialog for configuring mouse options

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TDialog
            TMouseDialog

=head1 SYNOPSIS

  use TUI::Gadgets::MouseDialog;

  my $dlg = new_TMouseDialog();

  my $result = $deskTop->execView($dlg);

=head1 DESCRIPTION

C<TMouseDialog> implements a small configuration dialog for mouse-related
options.

The dialog contains a scrollbar that controls the double-click delay, a
visual test area for mouse double-click detection and standard I<OK> and
I<Cancel> buttons. Changes to the delay value are reflected in the global
mouse event configuration.

=head1 CONSTRUCTOR

=head2 new

  my $dlg = TMouseDialog->new();

Creates a new mouse options dialog.

=head2 new_TMouseDialog

  my $dlg = new_TMouseDialog();

Factory-style constructor.

=head1 METHODS

=head2 handleEvent

  $dlg->handleEvent($event);

Processes command and broadcast events.

The dialog updates C<$doubleDelay> when the scrollbar value changes and
restores the original value when the cancel command is received.

=head1 SEE ALSO

L<TUI::Dialogs::Dialog>,
L<TUI::Gadgets::ClickTester>,
L<TUI::Views::ScrollBar>

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
