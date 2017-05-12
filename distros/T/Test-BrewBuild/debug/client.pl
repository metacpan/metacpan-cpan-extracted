use warnings;
use strict;

use IO::Socket::INET;
use Storable;

my $mod = 'IO::Socket::INET';

my $sock = new IO::Socket::INET (
    PeerHost => 'localhost',
    PeerPort => 7800,
    Proto => 'tcp',
);
die "can't create socket\n" unless $sock;

$sock->send("cpanm $mod");

my $recv = Storable::fd_retrieve($sock);

print $$recv;
