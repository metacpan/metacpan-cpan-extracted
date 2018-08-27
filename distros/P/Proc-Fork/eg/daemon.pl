use strict;
use Proc::Fork;
use POSIX;

# One-stop shopping: fork, die on error, parent process exits.
run_fork { parent { exit } };

# Other daemon initialization activities.
$SIG{INT} = $SIG{TERM} = $SIG{HUP} = $SIG{PIPE} = \&some_signal_handler;
POSIX::setsid() == -1 and die "Cannot start a new session: $!\n";
close $_ for *STDIN, *STDOUT, *STDERR;

# rest of daemon program follows
