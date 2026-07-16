use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use Time::HiRes qw(time);

# Self-contained proof for examples/sse-custom-events: open an SSE stream, POST a
# message on a second connection, and confirm the message is broadcast into the
# open stream alongside the periodic ticks.
#
# Start the app first:
#   pagi-server -p 5094 app.pl
# then:
#   perl probe.pl [port]

my $port = $ARGV[0] || 5094;

sub connect_to {
    IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')
        or die "connect to 127.0.0.1:$port failed: $!";
}

# Open the SSE stream (the Accept header promotes the request to SSE).
my $sse = connect_to();
$sse->autoflush(1);
print $sse "GET /events HTTP/1.1\r\nHost: localhost\r\nAccept: text/event-stream\r\n\r\n";

my $sel = IO::Select->new($sse);
my $buf = '';
sub drain {
    my $secs = shift;
    my $end  = time + $secs;
    while (time < $end) {
        if ($sel->can_read(0.2)) {
            my $n = sysread($sse, my $c, 8192);
            last unless $n;
            $buf .= $c;
        }
    }
}

drain(2.2);                       # collect a tick or two first
my $before_post = $buf;

# Broadcast a message on a SEPARATE connection.
my $msg = 'hello from probe';
my $post = connect_to();
$post->autoflush(1);
print $post "POST /say HTTP/1.1\r\nHost: localhost\r\nContent-Length: ${\ length $msg}\r\nConnection: close\r\n\r\n$msg";
{ local $/; <$post>; }            # drain the 202
close $post;

drain(2.0);                       # the message should arrive in the SSE stream now
close $sse;

(my $show = $buf) =~ s/\r//g;
print "=== SSE stream ===\n$show\n=== END ===\n";
print "saw periodic ticks:                   ", ($buf =~ /event: tick/ ? 'YES' : 'no'), "\n";
print "tick(s) arrived before the POST:       ", ($before_post =~ /event: tick/ ? 'YES' : 'no'), "\n";
print "POSTed message broadcast to the stream:", ($buf =~ /event: message\s*\ndata: \Q$msg\E/ ? ' YES' : ' no'), "\n";
