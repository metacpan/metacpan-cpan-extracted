=pod

=head1 NAME

Until now, the values in the dialog box would repeatedly be lost whenever you 
closed and reopened it.
For this reason, the values are now saved to a Class::Struct object.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/03_-_Dialoge/35_-_Werte_im_Dialog_merken>

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                && !$ENV{AUTOMATED_TESTING}
                                && !$ENV{NONINTERACTIVE_TESTING};

BEGIN {
  use_ok 'TUI::App';
  use_ok 'TUI::Objects';
  use_ok 'TUI::Drivers';
  use_ok 'TUI::Views';
  use_ok 'TUI::Menus';
  use_ok 'TUI::Dialogs';
  use_ok 'TUI::toolkit';
}

BEGIN {
  package TMyApp;

  use TUI::App;        # TApplication
  use TUI::Objects;    # Window section (TRect)
  use TUI::Drivers;    # Hotkey
  use TUI::Views;      # Event (cmQuit)
  use TUI::Menus;      # Status line and menu
  use TUI::Dialogs;    # Dialogs
  use TUI::toolkit;

  use constant {
    cmAbout => 1001,    # Display About
    cmList  => 1002,    # File list
    cmPara  => 1003,    # Parameters
  };

  # The values from the dialog are stored in the following Class::Struct based 
  # on a ArrayRef.
  # The order of the data B<must> be exactly the same as when the components 
  # were created; otherwise, an assert might be triggered.
  # With TUI::Vision, an ArrayRef had to be used instead of a Pascal record or 
  # C struct; this is important when porting applications.
  use Class::Struct 'TParameterData' => [
    print => '$',
    font  => '$',
    note  => '$',
  ];

  extends TApplication;

  has parameterData  => ( is => 'rw' );    # Data for the Parameter Dialog

  # The constructor must be inherited here; this derived class is needed to 
  # load the dialog data with default values.

  sub BUILD;             # New Constructor 
  sub initStatusLine;    # Status line
  sub initMenuBar;       # Menu
  sub handleEvent;       # Event handler
  sub myParameter;       # new function for a dialog.

  # We want to use a console resolution like MS DOS.
  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  # The Constructor that loads the values for the dialog.
  # The data structure for the radio buttons is simple. 0 is the first button, 
  # 1 is the second, 2 is the third, and so on.
  # For checkboxes, it's best to use a binary approach. In the example, the 
  # first and third checkboxes are selected.
  sub BUILD {
    my $self = shift;
    $self->{parameterData} = TParameterData->new(
      print => 0b0101,
      font  => 2,
      note  => 'Hello world',
    );
    return;
  }

  sub initStatusLine {
    my ( $class, $r ) = @_;
    $r->{a}{y} = $r->{b}{y} - 1;
    return 
      new_TStatusLine( $r,
        new_TStatusDef( 0, 0xFFFF ) +
          new_TStatusItem( '~Alt+X~ Exit', kbAltX, cmQuit ) +
          new_TStatusItem( '~F10~ Menu', kbF10, cmMenu ) +
          new_TStatusItem( '~F1~ Help', kbF1, cmHelp )
      );
  }

  # The menu is expanded to include parameters and close.
  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r,
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( '~L~ist', cmList, kbF2, hcNoContext, 'F2' ) +
          new_TMenuItem( '~P~arameter', cmPara, hcNoContext ) +
          newLine +
          new_TMenuItem( '~C~lose', cmClose, kbAltF3, hcNoContext, 'Alt-F3' ) +
          newLine +
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~H~elp', hcNoContext ) + 
          new_TMenuItem( '~A~bout', cmAbout, hcNoContext )
      );
  }

  # Here, the command C<cmPara> opens a dialog box.
  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );

    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmAbout == $_ and do {
          last;
        };
        cmList == $_ and do {
          last;
        };
        cmPara == $_ and do {
          $self->myParameter();
          last;
        };
        DEFAULT: {
          return;
        }
      }
    }
    $self->clearEvent( $event );
    return;
  }

  # The dialog is now loading with values.
  # You do this once you're done creating components.
  sub myParameter {
    my $self = shift;
    my $r    = new_TRect( 0, 0, 35, 15 );
    $r->move( 23, 3 );
    my $dlg = new_TDialog( $r, 'Parameter' );
    WITH: for ( $dlg ) {
      # CheckBoxes
      $r->assign( 2, 3, 18, 7 );
      my $view = new_TCheckBoxes( $r,
        new_TSItem('~F~ile',
        new_TSItem('~L~ine',
        new_TSItem('~D~ate',
        new_TSItem('~T~ime',
        undef))))
      );
      $_->insert( $view );
      # Label for CheckGroup.
      $r->assign( 2, 2, 10, 3 );
      $_->insert( new_TLabel( $r, '~P~rint', $view ) );

      # RadioButtons
      $r->assign( 21, 3, 33, 6 );
      $view = new_TRadioButtons( $r,
        new_TSItem('~B~ig',
        new_TSItem('~M~edium',
        new_TSItem('~S~mall',
        undef)))
      );
      $_->insert( $view );
      # Label for RadioGroup.
      $r->assign( 20, 2, 31, 3 );
      $_->insert( new_TLabel( $r, 'Font ~w~idth', $view ) );

      # Input Line
      $r->assign( 3, 10, 32, 11 );
      $view = new_TInputLine( $r, 50 );
      $_->insert( $view );
      # Label for the Input Line
      $r->assign( 2, 9, 10, 10 );
      $_->insert( new_TLabel( $r, '~N~ote', $view ) );

      # Ok-Button
      $r->assign( 7, 12, 17, 14 );
      $_->insert( new_TButton( $r, '~O~K', cmOK, bfDefault ) );

      # Cancel-Button
      $r->move( 12, 0 );
      $_->insert( new_TButton( $r, '~C~ancel', cmCancel, bfNormal ) );
    }
	  $dlg->setData( $self->{parameterData} );    # Load the 'Values' dialog box.
    my $dummy = $deskTop->execView( $dlg );      # Run the dialog.
    if ( $dummy == cmOK ) {    # When you close the dialog with 'OK', ..
      # .. load the data from the dialog into an ArrayRef.
      $dlg->getData( $self->{parameterData} );
    }
    # Dialog and memory are automatically released.
    return;
  }

  $INC{"TMyApp.pm"} = 1;
}

use_ok 'TMyApp';
SKIP: {
  skip 'Manual test not enabled', 3 unless ManualTestsEnabled();
  my $myApp;
  lives_ok { $myApp = new_ok( 'TMyApp' ) or die } 'init';
  lives_ok { $myApp->run()                      } 'run';
  lives_ok { undef $myApp                       } 'done';
}

done_testing;
