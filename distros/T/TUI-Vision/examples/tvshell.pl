#----------------------------------------------------------#
#                                                          #
#   Turbo Vision Shell Demo                                #
#                                                          #
#----------------------------------------------------------#
#
#      Turbo Vision - Version 2.0 (Perl Edition)
#
#      Demonstrates the use of a command shell
#
#
package TShell;

use TUI::App;
use TUI::Views;
use TUI::Drivers;
use TUI::Menus;
use TUI::MsgBox;
use TUI::toolkit;

extends TApplication;

use constant cmRunProgram => 1000;

sub BUILD {
  my ( $self, $args ) = @_;
}

sub shell {
  my ( $self ) = @_;

  unless ( THardwareInfo->isa( 'TUI::Drivers::HardwareInfo::Win32' ) ) {
    messageBox( 'This feature is only available on Windows.', 
      mfOKButton | mfInformation );
    return;
  }

  $self->suspend();
  print "Type EXIT to return...\n";
  system( $ENV{COMSPEC} );
  $self->resume();
  $self->redraw();
  return;
}

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {
      cmRunProgram == $_ and do {
        $self->shell();
        last;
      };

      DEFAULT: {
        return;
      }
    } #/ SWITCH: for ( $event->{message}{command} )
    $self->clearEvent( $event );
  }
  return;
}

# Purpose: Defines the pulldown menus used in Shell
sub initMenuBar {
  my ( $class, $bounds ) = @_;
  $bounds->{b}{y} = $bounds->{a}{y} + 1;
  return new_TMenuBar( $bounds,
    new_TSubMenu( '~R~un', 0 ) +
      new_TMenuItem( '~D~os Shell', cmRunProgram, 0, hcNoContext )
  );
}

# Purpose: Defines the status line that is displayed in the bottom line of 
# the screen within TShell
sub initStatusLine {
  my ( $class, $bounds ) = @_;
  $bounds->{a}{y} = $bounds->{b}{y} - 1;
  return new_TStatusLine( $bounds,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( '',             kbF10,  cmMenu ) +
      new_TStatusItem( '~Alt-X~ Exit', kbAltX, cmQuit )
  );
}

package main;

# Create an instance of the TShell object
my $shell = TShell->new();
$shell->run();

#----------------------------------------------------------#

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

tvshell.pl - L<TUI::Vision> command shell demonstration

=head1 SYNOPSIS

  tvshell.pl [options]

  Options:
    -?, --help    Show brief usage information
        --man     Show the complete manual

=head1 DESCRIPTION

This example demonstrates how a L<TUI::Vision> application can temporarily
leave the text user interface to run the Windows command processor and
then restore the application display.

The Run menu contains a command that suspends the L<TUI::Vision> application,
starts the command interpreter specified by C<COMSPEC>, resumes the
application after the command interpreter exits, and redraws the screen.

The I<DOS Shell> is available only when the 
L<Win32 backend|TUI::Drivers::HardwareInfo::Win32> is active.

=head1 DEMONSTRATED FEATURES

=over 4

=item *

Creating a simple L<TApplication|TUI::App::Application> subclass.

=item *

Defining and handling an application-specific command.

=item *

Creating a menu bar and status line.

=item *

Suspending and resuming a L<TUI::Vision> application.

=item *

Running the Windows command processor outside the TUI.

=item *

Redrawing the application after returning from the command processor.

=back

=head1 SEE ALSO

L<TUI::App>,
L<TUI::Drivers>,
L<TUI::Menus>,
L<TUI::Views>

=cut
