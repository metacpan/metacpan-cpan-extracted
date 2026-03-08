# Run with: remperl HOST examples/signal-catcher.pl
# Runs for 5 seconds on the remote side, reporting any signals it receives.
use v5.36;
use Time::HiRes qw(time sleep);

my $start = time;

for my $sig (qw(INT TERM QUIT HUP)) {
    $SIG{$sig} = sub {
        printf "SIG%-4s +%.2fs\n", $sig, time - $start;
    };
}

my $end = $start + 5;
while (time < $end) {
    sleep(0.05);
}
