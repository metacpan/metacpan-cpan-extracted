=pod

=head1 NAME

Hello World with TVision. The text is displayed in a message box.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/01_-_Einfuehrung/10_-_Hello_World>

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::App';
  use_ok 'TUI::MsgBox';
}

use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                && !$ENV{AUTOMATED_TESTING}
                                && !$ENV{NONINTERACTIVE_TESTING};

SKIP: {
  skip 'Manual test not enabled', 3 unless ManualTestsEnabled();
  my $myApp;
  lives_ok { $myApp = TApplication->new() } 'TApplication object created';
  isa_ok( $myApp, TApplication );
  lives_ok {
    messageBox('Hello World !', mfOKButton);
    # $myApp->run();    # If you want to continue.
  } 'TApplication object executed successfully';
};

done_testing;
