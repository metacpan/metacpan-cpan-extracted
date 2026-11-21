#---------------------------------------------------------#
#                                                         #
#   Turbo Vision Hello World Demo Source File             #
#                                                         #
#---------------------------------------------------------#
#
#      Turbo Vision - Version 1.0
#
#      Copyright (c) 1992 by Borland International
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

exit main( @ARGV+1, [ $0, @ARGV ] );

#---------------------------------------------------------#

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

# Command line options handling for help and manual pages
BEGIN {
  my ( $help, $man );
  GetOptions(
    'help|?' => \$help,
    'man'    => \$man,
  ) or pod2usage( -verbose => 0, -exitval => 2 );
  pod2usage( -verbose => 0, -exitval => 0 ) if $help;
  pod2usage( -verbose => 2, -exitval => 0 ) if $man;
}

__END__

=pod

=head1 NAME

hello.pl - Turbo Vision Hello World demonstration

=head1 SYNOPSIS

  hello.pl [options]

  Options:
    -?, --help    Show brief usage information
        --man     Show the complete manual

=head1 DESCRIPTION

This example demonstrates the basic structure of an interactive
I<Turbo Vision> application.

Unlike a traditional "Hello, World!" program, it does not simply
write text and terminate.  It creates a complete event-driven
application with a L<TMenuBar|TUI::Menus::MenuBar>, a
L<TDeskTop|TUI::App::DeskTop>, a
L<TStatusLine|TUI::Menus::StatusLine>, and a modal
L<TDialog|TUI::Dialogs::Dialog>.

Select C<Greeting...> from the C<Hello> menu or press C<Alt-G> to open
the dialog.  The program can be terminated by selecting C<Exit> or by
pressing C<Alt-X>.

=head1 DEMONSTRATED FEATURES

The example demonstrates the following I<Turbo Vision> concepts:

=over

=item *

Deriving an application class from L<TApplication|TUI::App::Application>.

=item *

Creating a menu bar by overriding C<initMenuBar()>.

=item *

Creating a status line by overriding C<initStatusLine()>.

=item *

Defining and dispatching an application-specific command.

=item *

Handling command events by overriding C<handleEvent()>.

=item *

Constructing and executing a modal L<TDialog|TUI::Dialogs::Dialog>.

=item *

Adding L<TStaticText|TUI::Dialogs::StaticText> and
L<TButton|TUI::Dialogs::Button> views to a dialog.

=item *

Starting the inherited I<Turbo Vision> event loop with C<run()>.

=back

=head1 USER INTERFACE

The menu bar contains a C<Hello> submenu with the following items:

=over

=item C<Greeting...>

Opens a modal dialog titled C<Hello, World!>.  The dialog displays the
question C<How are you?> and offers four buttons.

All four buttons close the dialog.  Their different labels are used
only to demonstrate the construction and placement of button views.

=item C<Exit>

Terminates the application.

=back

The status line provides C<Alt-X> as a shortcut for exiting the
application.  C<F10> activates the menu bar.

=head1 IMPLEMENTATION

C<THelloApp> is derived from L<TApplication|TUI::App::Application>.  Most
application behavior, including the desktop and the main event loop, is
inherited from I<Turbo Vision>.

The application overrides C<initMenuBar()> and C<initStatusLine()> to
construct its user interface.  Selecting C<Greeting...> generates the
application-defined command C<GreetThemCmd>.

C<handleEvent()> first invokes the inherited event handler and then
checks for C<GreetThemCmd>.  When that command is received,
C<greetingBox()> creates and executes the modal dialog.  The event is
cleared after it has been handled.

=head1 ORIGINAL SOURCE

This program is a Perl port of C<HELLO.CPP>, the I<Turbo Vision>
"Hello, World!" demonstration supplied with the I<Turbo Vision> 1.0
documentation.

The example is introduced in Chapter 1 of the Borland International
manual I<Turbo Vision> for C++ Programmer's Guide.

The original program demonstrates the fundamental components of an
I<Turbo Vision> application and is subsequently used by the manual to
explain L<TApplication|TUI::App::Application>, event handling,
menus, status lines, dialogs, and the inherited C<run()> method.

The Perl port preserves the structure and observable behavior of the
original example while expressing it through the L<TUI::Vision> API.

=head1 SEE ALSO

L<TUI::App>,
L<TUI::Dialogs>,
L<TUI::Drivers>,
L<TUI::Menus>,
L<TUI::Objects>,
L<TUI::Views>

=head1 COPYRIGHT AND LICENSE

The original example contains the following copyright notice:

  Turbo Vision - Version 1.0

  Copyright (c) 1992 by Borland International
  All Rights Reserved.

This Perl port retains the copyright and provenance information of the
original example.  See the L<TUI::Vision> distribution for applicable
licensing information.

=cut
