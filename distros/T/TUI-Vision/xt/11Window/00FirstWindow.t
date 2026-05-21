=pod

=head1 NAME

First memo window.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/11_-_Fenster/00_-_Erstes_Fenster>

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                && !$ENV{AUTOMATED_TESTING}
                                && !$ENV{NONINTERACTIVE_TESTING};

BEGIN {
  use_ok 'TUI::toolkit';
  use_ok 'TUI::Objects';
  use_ok 'TUI::Views';
  use_ok 'TUI::App';
}

BEGIN {
  package TMyApp;

  use TUI::toolkit;
  use TUI::Objects;
  use TUI::Views;
  use TUI::App;

  extends TApplication;

  # We want to use a console resolution like MS DOS.
  sub BUILDARGS {
    my $args = shift->SUPER::BUILDARGS( @_ ) || return;
    $args->{bounds} = new_TRect( 0, 0, 80, 25 );
    return $args;
  }

  # The constructor is inherited so that a new window is created from the start.
  sub BUILD {
    # The parent is called up automatically.
    shift->newWindows();    # Create window.
    return;
  }

  # Create new window. A window are not usually opened modally, as you usually 
  # want to open several of them.
  sub newWindows {
    my $self = shift;
    my $r    = new_TRect( 0, 0, 60, 20 );
    my $win  = new_TWindow( $r, 'Window', wnNoNumber );
    $deskTop->insert( $win )
      if $self->validView( $win );
    return;
  }

  $INC{"TMyApp.pm"} = 1;
}

use_ok 'TMyApp';
SKIP: {
  skip 'Manual test not enabled', 2 unless ManualTestsEnabled();
  my $myApp = TMyApp->new();
  isa_ok( $myApp, TApplication );
  lives_ok { $myApp->run() } 'TMyApp object executed successfully';
}

done_testing;
