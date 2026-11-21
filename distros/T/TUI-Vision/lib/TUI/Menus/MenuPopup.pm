package TUI::Menus::MenuPopup;
# ABSTRACT: Pop-up menu with keyboard shortcut handling

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMenuPopup
  new_TMenuPopup
);

use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Drivers::Util qw(
  getAltChar
  getCtrlChar
);
use TUI::Drivers::Const qw(
  evKeyDown
  evCommand
);
use TUI::Menus::MenuBox;
use TUI::Objects::Rect;
use TUI::Views::View;

sub TMenuPopup() { __PACKAGE__ }
sub name { 'TMenuPopup' }
sub new_TMenuPopup { __PACKAGE__->from(@_) }

extends TMenuBox;

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds => Object,
      menu   => Maybe[Object],
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  my $args2 = $class->SUPER::BUILDARGS(
    bounds     => $args1->{bounds},
    menu       => $args1->{menu},
    parentMenu => undef,
  );
  return { %$args1, %$args2 };
}

sub from {    # $obj ($bounds, $menu)
  state $sig = signature(
    method => 1,
    pos => [Object, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], menu => $args[1] );
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if ( $event->{what} == evKeyDown ) {
    my $keyCode = $event->{keyDown}{keyCode};
    my $item = $self->findItem( getCtrlChar( $keyCode ) );
    $item = $self->hotKey( $keyCode )
      if !$item;
    if ( $item && TView->commandEnabled( $item->{command} ) ) {
      $event->{what} = evCommand;
      $event->{message}{command} = $item->{command};
      $event->{message}{infoPtr} = undef;
      $self->putEvent( $event );
      $self->clearEvent( $event );
    }
    elsif ( getAltChar( $keyCode ) ne "\0" ) {
      $self->clearEvent( $event );
    }
  }
  $self->SUPER::handleEvent( $event );
  return;
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new(
    bounds => TRect->new(),
    menu   => undef,
  );
}

1

__END__

=pod

=head1 NAME

TUI::Menus::MenuPopup - pop-up menu with keyboard shortcut handling

=head1 HIERARCHY

  TObject
    TView
      TMenuView
        TMenuBox
          TMenuPopup

=head1 SYNOPSIS

  use TUI::Menus;
  use TUI::Objects;

  my $bounds = TRect->new( ax => 10, ay => 5, bx => 40, by => 12 );
  my $menu = new_TMenu(
    new_TMenuItem( '~A~dd Watch', 300, 0 ) +
    new_TMenuItem( '~D~elete Watch', 301, 0 ),
  );
  my $popup = new_TMenuPopup( $bounds, $menu );
  my $command = $desktop->execView( $popup );

=head1 DESCRIPTION

C<TMenuPopup> is a specialized menu box for standalone pop-up menus. In
addition to the keyboard navigation provided by L<TMenuBox>, it activates menu
items using Ctrl mnemonics and supports menu-item hot keys. Unmatched Alt
keystrokes are consumed by the popup.

=head2 Commonly Used Features

Construct a popup with L</new_TMenuPopup>, providing its bounds and a menu
built from C<new_TMenu> and C<new_TMenuItem>. Pass it to 
C<< $desktop->execView >> to display it and receive the selected command.

=head1 CONSTRUCTOR

=head2 new

  my $popup = TMenuPopup->new( bounds => $bounds, menu => $menu );

Creates a pop-up menu view.

=over

=item bounds

Bounding rectangle of the menu view (L<TRect|TUI::Objects::Rect>).

=item menu

Menu structure defining the items displayed by the pop-up (I<TMenu>).
This parameter is required but may be C<undef>.

=back

=head2 new_TMenuPopup

  my $popup = new_TMenuPopup($bounds, $menu);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 handleEvent

  $popup->handleEvent($event);

Processes Ctrl mnemonic and menu-item hot-key events before delegating menu
navigation and selection to L<TMenuBox>.

=head1 SEE ALSO

L<TMenuBox|TUI::Menus::MenuBox>,
L<TMenuView|TUI::Menus::MenuView>,
L<TMenuItem|TUI::Menus::MenuItem>

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
