#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use IO::Socket::INET ();
use Socket;

use Test::More;

## Low level connections to the server used in tests
my $s;
my $rserve_host = $ENV{RSERVE_HOST} || 'localhost';
my $rserve_port = $ENV{RSERVE_PORT} || 6311;
my $rserve = IO::Socket::INET->new(PeerAddr => $rserve_host,
                                   PeerPort => $rserve_port);
if ($rserve) {
    plan tests => 3;
    $rserve->read(my $response, 32);
    die "Unrecognized server ID" unless
        substr($response, 0, 12) eq 'Rsrv0103QAP1';

    socket($s, PF_INET, SOCK_STREAM, getprotobyname('tcp')) ||
        die "socket: $!";
    connect($s, sockaddr_in($rserve_port, inet_aton($rserve_host))) ||
        die "connect: $!";
    $s->read($response, 32);
    die "Unrecognized server ID" unless
        substr($response, 0, 12) eq 'Rsrv0103QAP1';
}
else {
    plan skip_all => "Cannot connect to Rserve server at localhost:6311";
}


use Statistics::R::IO::Rserve;
use Statistics::R::IO::REXPFactory;

use File::Temp;
my $local = File::Temp::tmpnam;

my $remote = Statistics::R::IO::Rserve->new($rserve)->eval( <<'END'
    local({
        f<-tempfile()
        writeBin(charToRaw("\1\2\3\4\5"), f)
        f
    })
END
)->to_pl->[0];

my $data = Statistics::R::IO::Rserve->new($rserve)->get_file($remote, $local);

my $expected = "\1\2\3\4\5";
is($data, $expected, 'get_file value');
    
my $file_contents = do {
    local $/;
    open(my $in, $local) or die "$!";
    <$in>
};

is($file_contents, $expected, 'get_file file');

$data = Statistics::R::IO::Rserve->new($rserve)->get_file($remote);
is($data, $expected, 'get_file nolocal');
