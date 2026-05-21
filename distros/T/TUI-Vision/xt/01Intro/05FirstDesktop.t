=pod

=head1 NAME

Most minimal Turbo Vision application.

=head1 SEE ALSO

L<Lazarus-FreeVision-Tutorial|https://github.com/sechshelme/Lazarus-FreeVision-Tutorial/tree/master/01_-_Einfuehrung/05_-_Erster_Desktop>

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::App';
}

use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                && !$ENV{AUTOMATED_TESTING}
                                && !$ENV{NONINTERACTIVE_TESTING};

SKIP: {
  skip 'Manual test not enabled', 3 unless ManualTestsEnabled();
  my $myApp;
  lives_ok { $myApp = TApplication->new() } 'TApplication object created';
  isa_ok( $myApp, TApplication );
  lives_ok { $myApp->run() } 'TApplication object executed successfully';
};

done_testing;

__END__

=pod

=head1 Console manual tests

For verifying console functionality that cannot be run as fully automated. To 
run the suite, follow these steps:

=over

=item 1. Install the necessary test libraries.

=item 2. Using a terminal, navigate to the current folder.

=item 3. Enable manual testing by defining the C<MANUAL_TESTS> environment 
variable (e.g. on cmd C<set MANUAL_TESTS=1>).

=item 4. Deactivate all standard environment variables for automated tests such 
as C<AUTOMATED_TESTING> or C<NONINTERACTIVE_TESTING> (e.g. with cmd 
C<set AUTOMATED_TESTING=>).

=item 5. Run C<prove> and follow the instructions in the command prompt.

=head2 Instructions for Windows testers

Test on Windows prints to console output, so in order to properly execute the 
manual tests, C<prove> must be invoked with argument C<-q> or C<-Q>. To do this 
run

  prove -l -q xt\*.t

=cut
