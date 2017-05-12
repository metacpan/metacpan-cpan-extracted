
use strict;
use warnings;

use Scriptalicious;

sub schleep { select(undef,undef,undef,shift); }

defined(my $pid = fork()) or barf "fork failed; $!";

$pid or schleep(0.5);

start_timer();

schleep(0.5);

say "elapsed (".($pid?"parent":"child").") = ".show_delta();

wait() if $pid;

exit( ($? & 255) || ($?>>8) || 0);


