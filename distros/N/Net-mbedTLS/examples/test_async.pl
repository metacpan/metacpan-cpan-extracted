use strict;
use warnings;

use blib;

use Net::mbedTLS;
use IO::Socket::INET;

my $tls = Net::mbedTLS->new();

my $peername = 'cpanel.net';

my $socket = IO::Socket::INET->new("$peername:443") or die;

$socket->blocking(0);

my $tlsclient = $tls->create_client($socket, servername => $peername);

my ($wrote, $read_w, $write_w, $result);

my $output = "\0" x 1024;
my $bytes_in;

my $payload_out = "GET / HTTP/1.1\r\nHost: $peername\r\n\r\n";
my $payload_at = 0;

while (1) {
    if ($payload_at < length($payload_out)) {
        $result = $tlsclient->write(substr($payload_out, $payload_at));

        if (!$result) {
            _wait_as_needed($tlsclient, $socket);
        }
        else {
            $payload_at += $result;
        }
    }
    else {
        $bytes_in = $tlsclient->read($output);

        if ($bytes_in) {
            print substr($output, 0, $bytes_in);
        }
        elsif (defined $bytes_in) {
            last;
        }
        else {
            _wait_as_needed($tlsclient, $socket);
        }
    }
}

sub _wait_as_needed {
    my ($tlsclient, $socket) = @_;

    if ($tlsclient->error eq Net::mbedTLS::ERR_SSL_WANT_READ) {
        vec( my $rin, fileno($socket), 1 ) = 1;
        select($rin, undef, undef, undef);
    }
    elsif ($tlsclient->error eq Net::mbedTLS::ERR_SSL_WANT_WRITE) {
        vec( my $rin, fileno($socket), 1 ) = 1;
        select(undef, $rin, undef, undef);
    }
    else {
        die "huh";
    }
}
