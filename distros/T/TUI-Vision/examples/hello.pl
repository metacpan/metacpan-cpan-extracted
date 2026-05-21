#---------------------------------------------------------#
#                                                         #
#   Turbo Vision Hello World Demo Source File             #
#                                                         #
#---------------------------------------------------------#
#
#      Turbo Vision - Version 2.0
#
#      Copyright (c) 1994 by Borland International
#      All Rights Reserved.
#
#
package THelloApp;

use strict;
use warnings;

use TUI::Objects;
use TUI::Menus;
use TUI::Drivers;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;

use TUI::toolkit;

sub ::new_THelloApp { __PACKAGE__->new() }

extends TApplication;

use constant {
  GreetThemCmd => 100,
};

sub BUILDARGS {
  return {
    %{ shift->SUPER::BUILDARGS() },
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

sub greetingBox {
	my ( $self ) = @_;
	my $d = new_TDialog( new_TRect( 25, 5, 55, 16 ), "Hello, World!" );

	$d->insert( new_TStaticText( new_TRect( 3, 5, 15, 6 ), "How are you?" ) );
	$d->insert(
		new_TButton( new_TRect( 16, 2, 28, 4 ), "Terrific", cmCancel, bfNormal ) );
	$d->insert(
		new_TButton( new_TRect( 16, 4, 28, 6 ), "Ok", cmCancel, bfNormal ) );
	$d->insert(
		new_TButton( new_TRect( 16, 6, 28, 8 ), "Lousy", cmCancel, bfNormal ) );
	$d->insert(
		new_TButton( new_TRect( 16, 8, 28, 10 ), "Cancel", cmCancel, bfNormal ) );

	my $result = $deskTop->execView( $d );
	$self->destroy( $d );
	return;
} #/ sub greetingBox

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {
      GreetThemCmd == $_ and do {
        $self->greetingBox();
        $self->clearEvent( $event );
        last;
      };
      DEFAULT: {
        last;
      }
    } #/ SWITCH: for ( $event->{message}...)
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub initMenuBar {
  my ( $class, $r ) = @_;
  $r->{b}{y} = $r->{a}{y} + 1;
  return new_TMenuBar( $r, 
    new_TSubMenu( "~H~ello", kbAltH ) +
      new_TMenuItem( "~G~reeting...", GreetThemCmd, kbAltG ) +
      newLine() +
      new_TMenuItem( "E~x~it", cmQuit, cmQuit, hcNoContext, "Alt-X" )
  );
} #/ sub initMenuBar

sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;
  return new_TStatusLine( $r,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
      new_TStatusItem( "",             kbF10,  cmMenu )
  );
} #/ sub initStatusLine

package main;

sub main {
  my $helloWorld = new_THelloApp();
  $helloWorld->run();
  return 0;
}

exit main( scalar @ARGV, \@ARGV );
