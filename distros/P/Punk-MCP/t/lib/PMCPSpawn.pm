package PMCPSpawn;
use 5.010;
use strict;
use warnings;

# A real Hyperman pool as a subprocess, for the live tests. Modelled on
# Punk-GraphQL's PGSpawn: the child is a fresh exec with stdout and stderr in a
# temp file before anything runs (a forked test inherits the harness's TAP
# pipe, and a leaked child hangs `make test`), stopped with TERM and then KILL,
# and reaped. An END block stops anything a die left running.

use Exporter 'import';
use File::Temp ();
use FindBin ();
use IO::Select ();
use IO::Socket::INET ();
use JSON::PP ();
use POSIX ();
use Socket ();
use Time::HiRes ();

our @EXPORT = qw(spawn_app stop_app free_port conn request raw_request
                 stream_open stream_wait mcp_body);

my @RUNNING;
END { stop_app($_) for grep { $_->{pid} } @RUNNING }

sub free_port {
    socket(my $s, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or die $!;
    setsockopt($s, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), 1);
    bind($s, Socket::pack_sockaddr_in(0, Socket::inet_aton('127.0.0.1'))) or die $!;
    my $port = (Socket::unpack_sockaddr_in(getsockname $s))[0];
    close $s;
    return $port;
}

# spawn_app($source, %o): $source defines the app class `LiveApp`. The runner
# adds Hyperman->run with %o{workers}, and %o{run} for extra run options.
sub spawn_app {
    my ($src, %o) = @_;
    my $port = $o{port} // free_port();
    my $workers = $o{workers} // 3;
    my $extra = $o{run} // '';
    my $script = File::Temp->new(TEMPLATE => 'pmcpsrvXXXXXX', TMPDIR => 1, SUFFIX => '.pl', UNLINK => 0);
    print {$script} $src, qq{
require Hyperman;
Hyperman->run(app => LiveApp->to_app, host => '127.0.0.1', port => $port,
              workers => $workers, $extra);
};
    close $script;
    my $out = File::Temp->new(TEMPLATE => 'pmcpoutXXXXXX', TMPDIR => 1, UNLINK => 0);
    my @inc = map { "-I$_" } grep { !ref && -d } @INC;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDIN, '<', '/dev/null';
        open STDOUT, '>&', $out or POSIX::_exit(1);
        open STDERR, '>&', $out or POSIX::_exit(1);
        exec $^X, @inc, "$script" or POSIX::_exit(1);
    }
    my $h = { pid => $pid, port => $port, out => "$out", script => "$script" };
    push @RUNNING, $h;
    for (1 .. 300) {
        last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        Time::HiRes::sleep(0.05);
    }
    Time::HiRes::sleep(0.3);    # every worker past its own start
    return $h;
}

sub stop_app {
    my ($h) = @_;
    return '' unless $h->{pid};
    kill 'TERM', $h->{pid};
    my $deadline = time + 10;
    my $reaped;
    while (time < $deadline) {
        if (waitpid($h->{pid}, 1) == $h->{pid}) { $reaped = 1; last }
        Time::HiRes::sleep(0.05);
    }
    if (!$reaped) { kill 'KILL', $h->{pid}; waitpid $h->{pid}, 0 }
    $h->{pid} = 0;
    my $log = do { local $/; open my $fh, '<', $h->{out} or return ''; <$fh> };
    unlink $h->{out}, $h->{script};
    return $log;
}

sub conn {
    my ($h) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$h->{port}", Proto => 'tcp', Timeout => 10);
    die "connect to 127.0.0.1:$h->{port}: $!" unless $s;
    return $s;
}

sub mcp_body { JSON::PP->new->canonical->encode({ jsonrpc => '2.0', id => $_[0], method => $_[1],
                                                   ($_[2] ? (params => $_[2]) : ()) }) }

sub _head {
    my ($method, $path, $headers, $body) = @_;
    my %h = (Host => 'localhost', %{ $headers || {} });
    $h{'Content-Length'} = length($body // '') if defined $body;
    $h{'Content-Type'} //= 'application/json' if defined $body;
    return "$method $path HTTP/1.1\r\n" . join('', map { "$_: $h{$_}\r\n" } sort keys %h) . "\r\n"
         . ($body // '');
}

# One request on a kept-alive socket, a Content-Length body back.
# Returns (status, \%headers, body).
sub request {
    my ($sock, $method, $path, $headers, $body) = @_;
    print {$sock} _head($method, $path, $headers, $body);
    local $/ = "\r\n";
    my $line = <$sock> // return (0, {}, '');
    my ($status) = $line =~ m{^HTTP/1\.\d (\d+)};
    my %hd;
    while (defined($line = <$sock>) && $line ne "\r\n") {
        chomp $line;
        my ($k, $v) = split /:\s*/, $line, 2;
        $hd{lc $k} = $v;
    }
    my $got = '';
    if (my $len = $hd{'content-length'}) { read $sock, $got, $len }
    return ($status, \%hd, $got);
}

# A request read to EOF, within $timeout seconds: a stream that ends. Returns
# (raw bytes, closed by the server: 1 or 0).
sub raw_request {
    my ($h, $method, $path, $headers, $body, $timeout) = @_;
    my $sock = conn($h);
    print {$sock} _head($method, $path, $headers, $body);
    my ($all, $closed) = ('', 0);
    my $sel = IO::Select->new($sock);
    my $end = Time::HiRes::time() + ($timeout // 10);
    while ((my $left = $end - Time::HiRes::time()) > 0) {
        last unless $sel->can_read($left);
        my $n = sysread $sock, my $buf, 65536;
        if (!$n) { $closed = 1; last }
        $all .= $buf;
    }
    return ($all, $closed);
}

# A stream left open: the socket, with its head read. Returns (socket, status).
sub stream_open {
    my ($h, $path, $headers) = @_;
    my $sock = conn($h);
    print {$sock} _head('GET', $path, $headers);
    my $head = '';
    my $sel = IO::Select->new($sock);
    while ($head !~ /\r\n\r\n/ && $sel->can_read(10)) {
        sysread($sock, my $buf, 1) or last;
        $head .= $buf;
    }
    my ($status) = $head =~ m{^HTTP/1\.\d (\d+)};
    return ($sock, $status // 0);
}

# Read a stream until $re matches what has arrived, or $timeout. Returns
# (everything read, matched, closed).
sub stream_wait {
    my ($sock, $re, $timeout, $buf) = @_;
    $buf //= '';
    my $sel = IO::Select->new($sock);
    my $end = Time::HiRes::time() + $timeout;
    while ($buf !~ $re) {
        my $left = $end - Time::HiRes::time();
        last if $left <= 0 || !$sel->can_read($left);
        my $n = sysread $sock, my $more, 65536;
        return ($buf, 0, 1) unless $n;
        $buf .= $more;
    }
    return ($buf, $buf =~ $re ? 1 : 0, 0);
}

1;
