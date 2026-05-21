
=pod

=head1 NAME

Application with custom window including scrollbars and indicator.

Insert a horizontal and a vertical scroll bar. We will also show you how to set 
the position of the slider. Use I<min> and I<max> to set the range and I<value> 
to specify the position of the slider. An indicator is also inserted to display 
the columns and rows.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/11_-_Fenster/15_-_Fenster_mit_Bedienelemte_ausstatten>

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
  use_ok 'TUI::toolkit';
}

# Custom window class with scrollbars and indicator
BEGIN {
  package TMyWindow;

  use TUI::Views;
  use TUI::Objects;
  use TUI::toolkit;

  extends TWindow;

  sub BUILD {
    my $self = shift;

    # Enable tiling/cascading
    $self->{options} |= ofTileable;

    # Horizontal scrollbar
    my $r = new_TRect(18, $self->{size}{y} - 1, $self->{size}{x} - 2, 
      $self->{size}{y});
    my $hScroll = new_TScrollBar($r);
    $hScroll->{minVal} = 0;
    $hScroll->{maxVal} = 100;
    $hScroll->{value} = 50;
    $self->insert($hScroll);

    # Vertical scrollbar
    $r = new_TRect($self->{size}{x} - 1, 1, $self->{size}{x}, 
      $self->{size}{y} - 1);
    my $vScroll = new_TScrollBar($r);
    $vScroll->{minVal} = 0;
    $vScroll->{maxVal} = 100;
    $vScroll->{value} = 20;
    $self->insert($vScroll);

    # Indicator for rows/columns
    $r = new_TRect(2, $self->{size}{y} - 1, 16, $self->{size}{y});
    # my $indicator = new_TIndicator($r);
    # $self->insert($indicator);

    return;
  }

  $INC{"TMyWindow.pm"} = 1;
}

# Application class
BEGIN {
  package TMyApp;

  use TUI::App;
  use TUI::Objects;
  use TUI::Drivers;
  use TUI::Views;
  use TUI::Menus;
  use TUI::toolkit;

  use constant {
    cmNewWin   => 1001,
    cmRefresh  => 1002,
  };

  extends TApplication;

  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ );
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
          new_TStatusItem( '~F1~ Help', kbF1, cmHelp )
      );
  }

  sub initMenuBar {
    my ( $class, $r ) = @_;
    $r->{b}{y} = $r->{a}{y} + 1;
    return 
      new_TMenuBar( $r,
        new_TSubMenu( '~F~ile', hcNoContext ) +
          new_TMenuItem( '~N~ew', cmNewWin, kbF4, hcNoContext, 'F4' ) +
          newLine +
          new_TMenuItem( '~E~xit', cmQuit, kbAltX, hcNoContext, 'Alt-X' ) +
        new_TSubMenu( '~W~indow', hcNoContext ) +
          new_TMenuItem( 'Tile', cmTile, kbNoKey, hcNoContext ) +
          new_TMenuItem( 'Cascade', cmCascade, kbNoKey, hcNoContext ) +
          new_TMenuItem( 'Close All', cmCloseAll, kbNoKey, hcNoContext ) +
          new_TMenuItem( 'Refresh', cmRefresh, kbNoKey, hcNoContext )
    );
  }

  sub newWindow {
    my $self = shift;
    use feature 'state';
    state $winCounter = 0;
    my $r   = new_TRect( 0, 0, 60, 20 );
    my $win = TMyWindow->from( $r, 'Window', ++$winCounter );
    if ( $self->validView( $win ) ) {
      $deskTop->insert( $win );
    }
    else {
      $winCounter--;
    }
  } #/ sub newWindow

  sub closeAll {
    $deskTop->forEach( sub {
      my $view = shift;
      $view->message( evCommand, cmClose, undef );
    } );
  }

  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->SUPER::handleEvent( $event );
    if ( $event->{what} == evCommand ) {
      SWITCH: for ( $event->{message}{command} ) {
        cmNewWin   == $_ and do { $self->newWindow(); last };
        cmCloseAll == $_ and do { $self->closeAll();  last };
        cmRefresh  == $_ and do { $self->redraw();    last };
      }
    }
    $self->clearEvent( $event );
  } #/ sub handleEvent

  $INC{"TMyApp.pm"} = 1;
}

use_ok 'TMyWindow';
use_ok 'TMyApp';

SKIP: {
  skip 'Manual test not enabled', 2 unless ManualTestsEnabled();
  my $app = TMyApp->new();
  isa_ok($app, TApplication);
  lives_ok { $app->run() } 'Application executed successfully';
}

done_testing;
