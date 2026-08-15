package PGSpawn;

# Spawning a real Hyperman server as a subprocess, for the wire tests.
#
# Tests never fork perl themselves: a forked test process inherits the
# harness's TAP pipe, END blocks, and buffered output - the classic
# smoker hang. The child here is a fresh exec with STDOUT and STDERR
# redirected to a temp file before anything else runs.

use 5.024;
use strict;
use warnings;
use Exporter 'import';
use FindBin ();
use File::Temp ();
use Socket ();
use IO::Socket::INET ();
use Time::HiRes ();

our @EXPORT = qw(pg_start pg_stop pg_port http_post http_get);

sub pg_port {
    socket(my $s, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or die $!;
    setsockopt($s, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), 1);
    bind($s, Socket::pack_sockaddr_in(0, Socket::inet_aton('127.0.0.1')))
        or die $!;
    my $port = (Socket::unpack_sockaddr_in(getsockname $s))[0];
    close $s;
    return $port;
}

# pg_start($app_source, %opts): write the app to a temp file, exec a
# fresh perl running it on Hyperman, wait for the port. The app source
# must end by defining the app class; the runner adds Hyperman->run.
sub pg_start {
    my ($src, %opts) = @_;
    my $port    = $opts{port} // pg_port();
    my $workers = $opts{workers} // 2;

    my $script = File::Temp->new(TEMPLATE => 'pgsrvXXXXXX', TMPDIR => 1,
                                 SUFFIX => '.pl', UNLINK => 0);
    print {$script} $src, <<"EOF";
require Hyperman;
Hyperman->run(app => App->to_app, host => '127.0.0.1', port => $port,
              workers => $workers);
EOF
    close $script;

    my $out = File::Temp->new(TEMPLATE => 'pgoutXXXXXX', TMPDIR => 1,
                              UNLINK => 0);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDOUT, '>&', $out or die "redirect: $!";
        open STDERR, '>&', $out or die "redirect: $!";
        exec $^X, (map { "-I$_" } "$FindBin::Bin/../lib",
                                  "$FindBin::Bin/lib"), "$script"
            or die "exec: $!";
    }

    for (1 .. 200) {
        last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        Time::HiRes::sleep(0.05);
    }
    return { pid => $pid, port => $port, out => "$out",
             script => "$script" };
}

sub pg_stop {
    my ($h, %opts) = @_;
    my $timeout = $opts{timeout} // 30;
    kill 'TERM', $h->{pid};
    my $deadline = time + $timeout;
    my $reaped;
    while (time < $deadline) {
        my $got = waitpid $h->{pid}, 1;   # WNOHANG
        if ($got == $h->{pid}) { $reaped = 1; last; }
        select undef, undef, undef, 0.05;
    }
    if (!$reaped) {
        kill 'KILL', $h->{pid};
        waitpid $h->{pid}, 0;
        die "server pid $h->{pid} outlived ${timeout}s after SIGTERM";
    }
    open my $fh, '<', $h->{out} or die "read $h->{out}: $!";
    local $/;
    my $log = <$fh>;
    unlink $h->{out}, $h->{script};
    return $log;
}

# A raw-socket HTTP/1.1 client - no LWP, no HTTP::Tiny surprises, and
# keep-alive when the caller reuses the handle it gets back.
sub _request {
    my ($port, $req, $sock) = @_;
    $sock ||= IO::Socket::INET->new(
        PeerAddr => "127.0.0.1:$port", Proto => 'tcp', Timeout => 10)
        or die "connect: $!";
    print {$sock} $req;

    my ($status, %headers, $body);
    local $/ = "\r\n";
    my $line = <$sock> // die "server closed the connection";
    ($status) = $line =~ m{^HTTP/1\.\d (\d+)} or die "bad status line: $line";
    while (defined($line = <$sock>) && $line ne "\r\n") {
        chomp $line;
        my ($k, $v) = split /:\s*/, $line, 2;
        $headers{lc $k} = $v;
    }
    my $len = $headers{'content-length'} // 0;
    if ($len) {
        my $got = read $sock, $body, $len;
        die "short body: $got of $len" unless $got == $len;
    }
    return ($status, \%headers, $body // '', $sock);
}

sub http_post {
    my ($port, $path, $body, %opts) = @_;
    my $type = $opts{type} // 'application/json';
    my $extra = join '', map { "$_: $opts{headers}{$_}\r\n" }
        keys %{ $opts{headers} || {} };
    return _request($port, join('',
        "POST $path HTTP/1.1\r\n",
        "Host: 127.0.0.1\r\n",
        "Content-Type: $type\r\n",
        "Content-Length: " . length($body) . "\r\n",
        $extra, "\r\n", $body), $opts{sock});
}

sub http_get {
    my ($port, $path, %opts) = @_;
    return _request($port, join('',
        "GET $path HTTP/1.1\r\n",
        "Host: 127.0.0.1\r\n\r\n"), $opts{sock});
}

1;
