use strict;
use IO::Socket::INET;
use Proc::Fork;

$SIG{CHLD} = 'IGNORE';

my $server = IO::Socket::INET->new(
	LocalPort => 7111,
	Type      => SOCK_STREAM,
	Reuse     => 1,
	Listen    => 10,
) or die "Couln't start server: $!\n";

my $client;
while ($client = $server->accept) {
    run_fork { child {
        # Service the socket
        sleep(10);
        print $client "Ooga! ", time % 1000, "\n";
        exit; # child exits. Parent loops to accept another connection.
    } }
}
