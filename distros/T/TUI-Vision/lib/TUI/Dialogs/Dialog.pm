package TUI::Dialogs::Dialog;
# ABSTRACT: Base dialog window class for dialog boxes

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TDialog
  new_TDialog
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Dialogs::Const qw(
  :cpXXXX
  :dpXXXX
);
use TUI::Drivers::Const qw(
  :evXXXX
  kbEsc
  kbEnter
);
use TUI::Views::Const qw(
  cmCancel
  cmDefault
  cmNo
  cmOK
  cmYes
  sfModal
  wfMove
  wfClose
  wnNoNumber
);
use TUI::Views::Palette;
use TUI::Views::Window;

sub TDialog() { __PACKAGE__ }
sub name() { 'TDialog' }
sub new_TDialog { __PACKAGE__->from(@_) }

extends TWindow;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds => Object,
      title  => Str, { alias => 'aTitle' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return $class->SUPER::BUILDARGS(
    bounds => $args->{bounds}, 
    title  => $args->{title}, 
    number => wnNoNumber,
  );
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{growMode} = 0;
  $self->{flags} = wfMove | wfClose;
  $self->{palette} = dpGrayDialog;
  return;
}

sub from {    # $obj ($bounds, $aTitle)
  state $sig = signature(
    method => 1,
    pos    => [Object, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], title => $args[1] );
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  state $paletteGray = TPalette->new(
    data => cpGrayDialog,
    size => length( cpGrayDialog ) 
  );
  state $paletteBlue = TPalette->new( 
    data => cpBlueDialog,
    size => length( cpBlueDialog ) 
  );
  state $paletteCyan = TPalette->new( 
    data => cpCyanDialog,
    size => length( cpCyanDialog ) 
  );

  SWITCH: for ( $self->{palette} ) {
    dpGrayDialog == $_ and return $paletteGray->clone();
    dpBlueDialog == $_ and return $paletteBlue->clone();
    dpCyanDialog == $_ and return $paletteCyan->clone();
  }
  return $paletteGray->clone();
} #/ sub getPalette

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

  $self->SUPER::handleEvent( $event );
  SWITCH: for ( $event->{what} ) {
    evKeyDown == $_ and do {
      local $_;
      SWITCH: for ( $event->{keyDown}{keyCode} ) {
        kbEsc == $_ and do {
          $event->{what}             = evCommand;
          $event->{message}{command} = cmCancel;
          $event->{message}{infoPtr} = undef;
          $self->putEvent( $event );
          $self->clearEvent( $event );
          last;
        };
        kbEnter == $_ and do {
          $event->{what}             = evBroadcast;
          $event->{message}{command} = cmDefault;
          $event->{message}{infoPtr} = undef;
          $self->putEvent( $event );
          $self->clearEvent( $event );
          last;
        };
      } #/ SWITCH: for ( $event->{keyDown}...)
      last;
    };

    evCommand == $_ and do {
      local $_;
      SWITCH: for ( $event->{message}{command} ) {
        cmOK == $_      || 
        cmCancel == $_  || 
        cmYes == $_     || 
        cmNo == $_ and do {
          if ( $self->{state} & sfModal ) {
            $self->endModal( $event->{message}{command} );
            $self->clearEvent( $event );
          }
          last;
        };
      } #/ SWITCH: for ( $event->{message}...)
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
} #/ sub handleEvent

sub valid {    # $bool ($command)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $command ) = $sig->( @_ );
  return $command == cmCancel
    ? true
    : $self->SUPER::valid( $command );
}

1

__END__

=pod

=head1 NAME

TUI::Dialogs::Dialog - base dialog window class for dialogs

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TWindow
          TDialog

=head1 SYNOPSIS

  use TUI::Dialogs;
  use TUI::Objects;

  my $bounds = TRect->new(
    ax => 5, ay => 3,
    bx => 40, by => 15
  );

  my $dialog = TDialog->new(
    bounds => $bounds,
    title  => 'Example'
  );

  my $result = $deskTop->execView($dialog);

=head1 DESCRIPTION

C<TDialog> implements the fundamental dialog window class used throughout Turbo
Vision. Dialogs provide a modal or non-modal container for controls such as
buttons, input fields, checkboxes, and labels.

The dialog class manages palette selection, keyboard handling for dialog
acceptance or cancellation, focus traversal, and modal termination logic.
It forms the basis for all higher-level dialog implementations.

Dialogs are typically executed modally using C<execView> on the desktop, but
may also be inserted directly as non-modal windows.

=head1 ATTRIBUTES

The following attributes are inherited from C<TWindow> and managed internally.

=over

=item growMode

Window growth behavior flag inherited from C<TWindow> (I<Int>).

=item flags

Internal flag mask controlling movement and closing behavior (I<Int>).

=item palette

Identifier of the dialog palette used for rendering (I<Int>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $dialog = TDialog->new(
    bounds => $bounds,
    title  => $title
  );

Creates a new dialog window.

=over

=item bounds

Bounding rectangle defining the dialog position and size (I<TRect>).

=item title

Title string displayed in the dialog frame (I<Str>).

=back

=head2 new_TDialog

  my $dialog = new_TDialog($bounds, $title);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 getPalette

  my $palette = $dialog->getPalette();

Returns a clone of the palette associated with the dialog color scheme.

Subclasses may override this method to provide custom color mappings.

=head2 handleEvent

  $dialog->handleEvent($event);

Processes keyboard and command events.

This method adds dialog-specific handling for keys such as Escape and Enter and
generates standard dialog commands like C<cmCancel> or C<cmDefault>.

=head2 valid

  my $bool = $dialog->valid($command);

Checks whether the dialog should accept the specified command.

The cancel command (C<cmCancel>) is always accepted. For validation commands,
this method queries all contained controls to determine whether the dialog state
is valid.

=head1 SEE ALSO

L<TUI::Dialogs::Button>,
L<TUI::Dialogs::InputLine>,
L<TUI::Dialogs::CheckBoxes>,
L<TUI::Dialogs::RadioButtons>,
L<TUI::Views::Window>,
L<TUI::App::DeskTop>

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
