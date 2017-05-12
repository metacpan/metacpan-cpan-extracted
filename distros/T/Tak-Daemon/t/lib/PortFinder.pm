# intentionally not changing package to jam the routine herein straight
# into the use-ing package. Yes, this is totally a hack.
#
# Code is almost verbatim (bar _check_port -> $_check_port because I'm
# polluting people's namespaces already) from Test::TCP 1.07 by
# Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt> which is perl licensed.

use IO::Socket::INET;
use strictures 1;

my $_check_port = sub {
    my ($port) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
};

sub empty_port {
    my $port = do {
        if (@_) {
            my $p = $_[0];
            $p = 19000 unless $p =~ /^[0-9]+$/ && $p < 19000;
            $p;
        } else {
            10000 + int(rand()*1000);
        }
    };

    while ( $port++ < 20000 ) {
        next if $_check_port->($port);
        my $sock = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        );
        return $port if $sock;
    }
    die "empty port not found";
}

