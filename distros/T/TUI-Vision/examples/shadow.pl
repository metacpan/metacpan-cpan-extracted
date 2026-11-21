#---------------------------------------------------------#
#                                                         #
#   Turbo Vision Shadow Demo Source File                  #
#                                                         #
#---------------------------------------------------------#
#
#   Turbo Vision - Version 2.0 (Perl Edition)
#
#   Copyright (c) 1990-1994, 1997 by Borland International
#   All Rights Reserved.
#
#   Based on SHADOW.PAS (Turbo Pascal 6.0, Turbo Vision).
#   Copyright (c) 1991 by tewi Verlag GmbH
#
package TShadowApp;

use strict;
use warnings;

use TUI::Objects;
use TUI::Menus;
use TUI::Drivers;
use TUI::App;
use TUI::Views;
use TUI::Dialogs;

use TUI::toolkit;

sub ::new_TShadowApp { __PACKAGE__->new() }

extends TApplication;

our ( $shadowAttr, $shadowSize );
*shadowAttr = \$TUI::Views::View::shadowAttr;
*shadowSize = \$TUI::Views::View::shadowSize;

use constant {
  cmShadowDialog => 112,
};

{
  package TShadowDialog;

  use strict;
  use warnings;

  use TUI::Objects;
  use TUI::Drivers;
  use TUI::App;
  use TUI::Validate;
  use TUI::Views;
  use TUI::Dialogs;

  use TUI::toolkit;

  extends TDialog;

  use constant {
    cmRedraw => 113,
  };

  # Data record in the order the controls are visited by TShadowDialog::getData.
  use Class::Struct DataRec => [
    attr => '$',
    x    => '$',
    y    => '$',
  ];

  sub BUILDARGS {
    return shift->SUPER::BUILDARGS( 
      bounds => new_TRect( 22, 4, 54, 16 ), 
      title  => 'Shadow Dialog',
    );
  }

  sub BUILD {
    my $self = shift;
    my $r = TRect->new();

    # Pascal's TNumInputLine is a TInputLine with a range validator here.
    # 255 needs three digits, so the attribute field uses maxLen 3.
    $r->assign( 16, 3, 20, 4 );
    my $attr = new_TInputLine( $r, 3, new_TRangeValidator( 0, 255 ) );
    $self->insert( $attr );

    $r->assign( 3, 3, 15, 4 );
    $self->insert( new_TLabel( $r, 'Shadow Attr', $attr ) );

    $r->assign( 16, 5, 20, 6 );
    my $x = new_TInputLine( $r, 2, new_TRangeValidator( 0, 20 ) );
    $self->insert( $x );

    $r->assign( 3, 5, 15, 6 );
    $self->insert( new_TLabel( $r, 'Shadow Size', $x ) );

    $r->assign( 23, 5, 27, 6 );
    my $y = new_TInputLine( $r, 2, new_TRangeValidator( 0, 20 ) );
    $self->insert( $y );

    $r->assign( 20, 5, 22, 6 );
    $self->insert( new_TLabel( $r, ':', $y ) );

    $r->assign( 9, 8, 22, 10 );
    $self->insert( new_TButton( $r, 'Draw View', cmRedraw, bfDefault ) );

    $self->selectNext( false );
    return;
  }

  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );
    if ( $event->{what} == evCommand ) {
      if ( $event->{message}{command} == cmRedraw ) {
        if ( $self->valid( cmRedraw ) ) {
          my $dataRec = DataRec->new();
          $self->getData( $dataRec );
          $shadowAttr      = int $dataRec->attr;
          $shadowSize->{x} = int $dataRec->x;
          $shadowSize->{y} = int $dataRec->y;
          $deskTop->redraw();
        }
        $self->clearEvent( $event );
      }
    }
    return;
  }
}

sub BUILDARGS {
  return {
    %{ shift->SUPER::BUILDARGS() },
    bounds => new_TRect( 0, 0, 80, 25 ),
  };
}

sub shadowDialog {
  my $self = shift;
  my $dlg = TShadowDialog->new();
  my $dataRec = DataRec->new(
    attr => 0+ $shadowAttr,
    x    => $shadowSize->{x},
    y    => $shadowSize->{y},
  );
  $dlg->setData( $dataRec );
  $deskTop->execView( $dlg );
  return;
}

sub handleEvent {
  my ( $self, $event ) = @_;
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evCommand ) {
    if ( $event->{message}{command} == cmShadowDialog ) {
      $self->shadowDialog();
      $self->clearEvent( $event );
    }
  }
  return;
}

sub initMenuBar {
  my ( $class, $r ) = @_;
  $r->{b}{y} = $r->{a}{y} + 1;
  return new_TMenuBar( $r,
    new_TSubMenu( "~F~ile", kbAltF )
      + new_TMenuItem( "~S~hadow Dialog", cmShadowDialog, kbF7, hcNoContext, 
        "F7" )
      + newLine()
      + new_TMenuItem( "E~x~it", cmQuit, kbAltX, hcNoContext, "Alt-X" )
  );
}

sub initStatusLine {
  my ( $class, $r ) = @_;
  $r->{a}{y} = $r->{b}{y} - 1;
  return new_TStatusLine( $r,
    new_TStatusDef( 0, 0xFFFF )
      + new_TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit )
      + new_TStatusItem( "~F10~ Menu",   kbF10,  cmMenu )
  );
}

package main;

sub main {
  my $shadowApp = new_TShadowApp();
  $shadowApp->run();
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

shadow.pl - Turbo Vision shadow demonstration

=head1 SYNOPSIS

  shadow.pl [options]

  Options:
    -?, --help    Show brief usage information
        --man     Show the complete manual

=head1 DESCRIPTION

C<shadow.pl> demonstrates the configurable drop shadows used by
I<Turbo Vision> L<TView|TUI::Views::View> objects.

The application provides a L<TDialog|TUI::Dialogs::Dialog> for changing
the global shadow attribute and the horizontal and vertical shadow
size.  Changes can be applied immediately so their effect on the user
interface can be observed directly.

Press C<F7> or select C<Shadow Dialog> from the File menu to open the
configuration dialog.

=head1 SHADOW DIALOG

The Shadow Dialog uses three numeric
L<TInputLine|TUI::Dialogs::InputLine> controls:

=over 4

=item C<Shadow Attr>

Sets the character attribute used to draw view shadows.

The value must be in the range 0 to 255.

=item C<Shadow Size>

Sets the horizontal and vertical size of view shadows.

Both values must be in the range 0 to 20.

=item C<Draw View>

When activated, the L<TButton|TUI::Dialogs::Button> causes the
L<TDialog|TUI::Dialogs::Dialog> to validate the entered values, apply
them to the global shadow settings, and redraw the desktop so that the
changes become immediately visible.

=back

=head1 KEYBOARD SHORTCUTS

=over 4

=item C<F7>

Open the Shadow Dialog.

=item C<F10>

Activate the menu bar.

=item C<Alt-X>

Exit the application.

=back

=head1 DEMONSTRATED FEATURES

This example demonstrates:

=over 4

=item *

Changing the global I<Turbo Vision> shadow attribute.

=item *

Changing the horizontal and vertical shadow size.

=item *

Using validated numeric input fields.

=item *

Using C<getData()> and C<setData()> to exchange structured data with
a L<TDialog|TUI::Dialogs::Dialog>.

=item *

Handling an application-specific dialog command.

=item *

Redrawing the desktop after changing global display properties.

=back

=head1 ORIGINAL SOURCE

This program is a Perl port based on C<SHADOW.PAS>, an I<Turbo Vision>
example for Turbo Pascal 6.0.

The original example is attributed to:

  Copyright (c) 1991 by tewi Verlag GmbH

The Perl version preserves the purpose and observable behavior of the
original example while adapting its dialog controls and data exchange
to the L<TUI::Vision> API.

=head1 SEE ALSO

L<TUI::App>,
L<TUI::Dialogs>,
L<TUI::Validate>,
L<TUI::Views>

=head1 COPYRIGHT

The original Pascal example is attributed to:

  Copyright (c) 1991 by tewi Verlag GmbH

This Perl version is based on that example and the I<Turbo Vision>
interfaces implemented by L<TUI::Vision>.

See the L<TUI::Vision> distribution for copyright and licensing
information relating to the Perl implementation.

=cut
