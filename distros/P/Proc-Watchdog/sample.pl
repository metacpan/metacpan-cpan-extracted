
use Proc::Watchdog;

my $w = new Proc::Watchdog;

# Let's set up the timer

$w->alarm(50);

# Your critical code goes here

#$w->reset;

# This is safe now...
