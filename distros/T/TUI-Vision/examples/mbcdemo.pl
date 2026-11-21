#---------------------------------------------------------#
#                                                         #
#    Turbo Vision MultiCheckBoxes Demo                    #
#                                                         #
#---------------------------------------------------------#
#
#      Turbo Vision - Version 2.0 (Perl Edition)
#
#      Demonstrates the TMultiCheckBoxes control.
#
#
package TMCBDemo;

use strict;
use warnings;

use TUI::Objects;
use TUI::Menus;
use TUI::Drivers;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;
use TUI::MsgBox;

use TUI::toolkit;

sub ::new_TMCBDemo { __PACKAGE__->new() }

extends TApplication;

use constant {
  cmDemoMCB => 1000,
};

sub BUILDARGS {
  return {
    %{ shift->SUPER::BUILDARGS() },
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

#
# Demo dialog showing the TMultiCheckBoxes control       
#
sub showMultiCheckBoxDemo {
  my ( $self ) = @_;

  # Build a HashRef chain (3 entries)
  # First -> Second -> Third -> undef
  my $items =  { value => 'Low',  next 
            => { value => 'Med',  next 
            => { value => 'High', next 
            => undef }}};

  # Create a dialog
  my $d = new_TDialog(
    new_TRect( 10, 4, 50, 18 ),
    "MultiCheckBoxes Demo"
  );

  # Insert a MultiCheckBoxes control
  my $mcb = TMultiCheckBoxes->new(
    bounds   => new_TRect( 3, 2, 30, 5 ),
    strings  => $items,
    selRange => 3,         # three states: "-", "+", "*"
    flags    => 0x0203,    # mask=0x03, shift=2 bits per item
    states   => "-+*",     # state characters
  );

  $d->insert( $mcb );

  # Buttons
  $d->insert( new_TButton( 
    new_TRect( 10, 8, 22, 10 ), "~O~k", cmOK, bfDefault ) );
  $d->insert( new_TButton( 
    new_TRect( 10, 10, 22, 12 ), "~C~ancel", cmCancel, bfNormal ) );

  # Show dialog
  my $res = $self->executeDialog( $d );

  # Retrieve final state (value bitfield)
  if ( $res == cmOK ) {
    my $result = $mcb->{value};
    my $msg    = sprintf "Final bitfield value: 0b%08b", $result;
    messageBox( $msg, mfInformation | mfOKButton );
  }

  $self->destroy( $d );
  return;
} #/ sub showMultiCheckBoxDemo

#
# Event handler                                          
#
sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evCommand ) {
    SWITCH: for ( $event->{message}{command} ) {

      cmDemoMCB == $_ and do {
        $self->showMultiCheckBoxDemo();
        $self->clearEvent( $event );
        last;
      };

      DEFAULT: { last }
    } #/ SWITCH: for ( $event->{message}...)
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

#
# Menu bar                                               
#
sub initMenuBar {
  my ( $class, $r ) = @_;
  $r->{b}{y} = $r->{a}{y} + 1;

  return new_TMenuBar(
    $r,
    new_TSubMenu( "~D~emo", kbAltD ) +
      new_TMenuItem( "~M~ultiCheck Demo...", cmDemoMCB, kbAltM ) +
      newLine() +
      new_TMenuItem( "E~x~it", cmQuit, cmQuit, hcNoContext, "Alt-X" )
  );
} #/ sub initMenuBar

#
# Status line                                            
#
sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;

  return new_TStatusLine(
    $r,
    new_TStatusDef( 0, 0xFFFF ) +
      new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
      new_TStatusItem( "",             kbF10,  cmMenu )
  );
} #/ sub initStatusLine

#
# Main entry point                                       
#
package main;

sub main {
  my $app = new_TMCBDemo();
  $app->run();
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

mbcdemo.pl - TMultiCheckBoxes control demonstration

=head1 SYNOPSIS

  mbcdemo.pl [options]

  Options:
    -?, --help    Show brief usage information
        --man     Show the complete manual

=head1 DESCRIPTION

This demo application demonstrates the
L<TMultiCheckBoxes|TUI::Dialogs::MultiCheckBoxes> control provided by
L<TUI::Vision>.

The example creates a dialog containing three items named C<Low>, C<Med>, 
and C<High>.  Each item can be cycled through three states, displayed as C<->, 
C<+>, and C<*>.

Select C<MultiCheck Demo...> from the Demo menu or press C<Alt-M> to open the 
demonstration dialog.

=head1 MULTICHECKBOXES CONTROL

L<TMultiCheckBoxes|TUI::Dialogs::MultiCheckBoxes> extends the usual checkbox 
concept, allowing each item to have more than two states.

This example configures the control with three states:

  states   => "-+*"
  selRange => 3

Each item therefore cycles through C<->, C<+>, and C<*> instead of being 
limited to an unchecked and checked state.

The example stores each selected state in a two-bit field:

  flags => 0x0203

The low byte defines the mask used for an individual item, while the high byte 
defines the number of bits by which successive item values are shifted.

With three items, their states are therefore combined into a single bitfield 
value.

=head1 RESULT

Press C<OK> to close the dialog and display the resulting bitfield in a message 
box.

The value represents the combined states of the C<Low>, C<Med>, and C<High> 
items.

Press C<Cancel> to close the dialog without displaying the value.

=head1 KEYBOARD SHORTCUTS

=over 4

=item C<Alt-M>

Open the MultiCheckBoxes demonstration dialog.

=item C<F10>

Activate the menu bar.

=item C<Alt-X>

Exit the application.

=back

=head1 DEMONSTRATED FEATURES

This example demonstrates:

=over 4

=item *

Creating and inserting a L<TMultiCheckBoxes|TUI::Dialogs::MultiCheckBoxes> 
control.

=item *

Configuring more than two states per item.

=item *

Defining the characters used to represent the available states.

=item *

Packing the states of several items into a single bitfield.

=item *

Building the item list used by a cluster control.

=item *

Retrieving the resulting value after executing a modal dialog.

=back

=head1 SEE ALSO

L<TUI::App>,
L<TUI::Dialogs>,
L<TUI::Menus>,
L<TUI::MsgBox>

=head1 COPYRIGHT AND LICENSE

  Turbo Vision - Version 2.0 (Perl Edition)

  Copyright (c) 2026 J. Schneider

This software is licensed under the MIT license.  See the LICENSE file
included with the L<TUI::Vision> distribution.

=cut
