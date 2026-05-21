=pod

=head1 NAME

The ListBox can also be sorted.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/06_-_Listen_und_ListBoxen/15_-_ListBox_sortiert>

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
  use_ok 'TUI::StdDlg';
  use_ok 'TUI::MsgBox';
  use_ok 'TUI::toolkit';
}

BEGIN {
  package TMyDialog;

  use TUI::Objects;
  use TUI::Drivers;
  use TUI::Dialogs;
  use TUI::StdDlg;
  use TUI::Views;
  use TUI::MsgBox;
  use TUI::toolkit;

  extends TDialog;

  has listBox          => ( is => 'rw' );
  has stringCollection => ( is => 'rw' );

  sub BUILDARGS;
  sub BUILD;
  sub handleEvent;

  # implementation

  use constant {
    cmDay => 1000,    # Local Event Constant
  };

  sub BUILDARGS {
    return shift->SUPER::BUILDARGS(
      bounds => new_TRect( 10, 5, 64, 17 ),
      title  => 'ListBox Demo',
      @_
    );
  }

  sub BUILD {
    my ( $self ) = @_;
    my @dow = qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday );

    # StringCollection
    $self->{stringCollection} = new_TStringCollection( 5, 5 );
    for my $day ( @dow ) {
      $self->{stringCollection}->insert( $day );
    }

    # Scroll bar for ListBox
    my $r         = new_TRect( 31, 2, 32, 7 );
    my $scrollbar = new_TScrollBar( $r );
    $self->insert( $scrollbar );

    # ListBox
    $r->{a}{x} = 5;
    $r->{b}{x}--;
    $self->{listBox} = new_TSortedListBox( $r, 1, $scrollbar );
    $self->{listBox}->newList( $self->{stringCollection} );
    $self->insert( $self->{listBox} );

    # Day-Button
    $r->assign( 5, 9, 18, 11 );
    my $btn_tag = new_TButton( $r, '~D~ay', cmDay, bfNormal );
    $self->insert( $btn_tag );

    # Cancel-Button
    $r->move( 15, 0 );
    my $btn_cancel = new_TButton( $r, '~C~ancel', cmCancel, bfNormal );
    $self->insert( $btn_cancel );

    # Ok-Button
    $r->move( 15, 0 );
    my $btn_ok = new_TButton( $r, '~O~K', cmOK, bfDefault );
    $self->insert( $btn_ok );

    return;
  } #/ sub BUILD

  my $getFocusedItem = sub {
    my $data = TListBoxRec->new();
    shift->getData( $data );
    return $data->items->at( $data->selection );
  };

  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );

    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmOK == $_ and do {
          last;
        };
        cmDay == $_ and do {
          # Read entry with focus
          # ... and output
          messageBox( mfOKButton, "Day of week: %s chosen", 
            $self->{listBox}->$getFocusedItem() );
          # End event
          $self->clearEvent( $event );
          last;
        };
        DEFAULT: {
          return;
        }
      }
    }
    return;
  }

  $INC{"TMyDialog.pm"} = 1;
}

BEGIN {
  package TMyApp;

  use TUI::App;        # TApplication
  use TUI::Objects;    # Window section (TRect)
  use TUI::Drivers;    # Hotkey
  use TUI::Views;      # Event (cmQuit)
  use TUI::Menus;      # Status line and menu
  use TMyDialog;
  use TUI::toolkit;

  use constant {
    cmDialog => 1001,    # Display Dialog
  };

  extends TApplication;

  sub initStatusLine;    # Status line
  sub initMenuBar;       # Menu
  sub handleEvent;       # Event handler

  # We want to use a console resolution like MS DOS.
  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  sub initStatusLine {
    my ( $class, $r ) = @_;
    $r->{a}{y} = $r->{b}{y} - 1;
    return
      new_TStatusLine( $r,
        new_TStatusDef( 0, 0xFFFF ) +
          new_TStatusItem( '~Alt+X~ Exit', kbAltX, cmQuit ) +
          new_TStatusItem( '~F10~ Menu', kbF10, cmMenu ) +
          new_TStatusItem( '~F1~ Help',  kbF1,  cmHelp ) +
          StdStatusKeys()
      );
  }

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return
      new_TMenuBar( $r,
        new_TSubMenu( '~F~ile', hcNoContext ) + 
          new_TMenuItem( 'E~x~it', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~O~ption', hcNoContext ) + 
          new_TMenuItem( 'Dia~l~og', cmDialog, kbNoKey, hcNoContext )
      );
  }

  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );

    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmDialog == $_ and do {
          my $myDialog = TMyDialog->new();
          if ( $self->validView( $myDialog ) ) {
            $deskTop->execView( $myDialog );    # Execute Dialog
            $myDialog = undef;                  # Release dialog and memory.
          }
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

  sub StdStatusKeys {
    my ( $next ) = @_;
    return
      new_TStatusItem('', kbAltX, cmQuit,
      new_TStatusItem('', kbF10, cmMenu,
      new_TStatusItem('', kbAltF3, cmClose,
      new_TStatusItem('', kbF5, cmZoom,
      new_TStatusItem('', kbCtrlF5, cmResize,
      new_TStatusItem('', kbF6, cmNext,
      new_TStatusItem('', kbShiftF6, cmPrev,
      $next)))))));
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
