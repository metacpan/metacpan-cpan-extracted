use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use Time::HiRes qw(time);

# Full-duplex wire probe for examples/duplex-http-stream. A normal HTTP client
# (and PAGI::Test::Client) won't exercise true full duplex, so this drives a raw
# socket: it sends a chunked request body over time and reads the response
# concurrently, proving the server streams the response while the request body is
# still open AND delivers later request chunks to the app mid-response.
#
# Start the app first:
#   pagi-server -p 5096 app.pl
# then:
#   perl probe.pl [port]

my $port = $ARGV[0] || 5096;
my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')
    or die "connect to 127.0.0.1:$port failed: $!";
$sock->autoflush(1);
my $sel = IO::Select->new($sock);
my $buf = '';

sub drain {
    my $secs = shift;
    my $end  = time + $secs;
    while (time < $end) {
        if ($sel->can_read(0.2)) {
            my $n = sysread($sock, my $c, 8192);
            return unless $n;
            $buf .= $c;
        }
    }
}

# Request with a chunked body fed over time (no Content-Length).
print $sock "POST /duplex HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\n\r\n";
print $sock sprintf("%x\r\n%s\r\n", length('hello'), 'hello');   # first chunk; body still open
drain(2.5);
my $after_first = $buf;
print $sock sprintf("%x\r\n%s\r\n", length('world'), 'world');   # second chunk, mid-response
drain(2.0);
print $sock "0\r\n\r\n";                                          # close the body
drain(1.5);
close $sock;

(my $show = $buf) =~ s/\r//g;
print "=== RAW RESPONSE ===\n$show\n=== END ===\n";
print "200 response:                         ", ($buf =~ m{HTTP/1\.1 200} ? 'YES' : 'no'), "\n";
print "ticked while request body still open: ", ($after_first =~ /tick 1/ ? 'YES (full-duplex response)' : 'no'), "\n";
print "echoed 'hello':                       ", ($buf =~ /echo: hello/ ? 'YES' : 'no'), "\n";
print "echoed 'world' (sent mid-response):   ", ($buf =~ /echo: world/ ? 'YES (full-duplex request)' : 'no'), "\n";
