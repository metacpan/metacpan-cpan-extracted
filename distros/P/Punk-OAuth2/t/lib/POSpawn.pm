package POSpawn;

# Spawn the MockIdP under a real Hyperman as a fresh subprocess. Tests
# never fork perl themselves - a forked test process inherits the TAP
# pipe and END blocks (the classic smoker hang); the child here is a
# fresh exec with STDOUT and STDERR redirected before anything runs.

use 5.024;
use strict;
use warnings;
use Exporter 'import';
use FindBin ();
use File::Temp ();
use Socket ();
use IO::Socket::INET ();
use Time::HiRes ();

our @EXPORT = qw(idp_start idp_stop);

sub _free_port {
    socket(my $s, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or die $!;
    setsockopt($s, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), 1);
    bind($s, Socket::pack_sockaddr_in(0, Socket::inet_aton('127.0.0.1')))
        or die $!;
    my $port = (Socket::unpack_sockaddr_in(getsockname $s))[0];
    close $s;
    return $port;
}

sub idp_start {
    my (%opts) = @_;
    my $port    = _free_port();
    my $workers = $opts{workers} // 2;

    # Carry the parent's whole @INC (blib for the XS, t/lib for MockIdP,
    # the local::lib) into the fresh interpreter, plus the test dirs.
    my @inc = ("$FindBin::Bin/lib", "$FindBin::Bin/../lib",
               grep { !ref } @INC);
    my $inc = join ",\n    ", map { "'$_'" } @inc;

    my $script = File::Temp->new(TEMPLATE => 'poidpXXXXXX', TMPDIR => 1,
                                 SUFFIX => '.pl', UNLINK => 0);
    print {$script} <<"EOF";
use strict; use warnings;
use lib (
    $inc
);
require MockIdP;
\$MockIdP::ISSUER = 'http://127.0.0.1:$port';
require Hyperman;
Hyperman->run(app => MockIdP::app(), host => '127.0.0.1', port => $port,
              workers => $workers);
EOF
    close $script;

    my $out = File::Temp->new(TEMPLATE => 'poidpoutXXXXXX', TMPDIR => 1,
                              UNLINK => 0);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDOUT, '>&', $out or die "redirect: $!";
        open STDERR, '>&', $out or die "redirect: $!";
        exec $^X, "$script" or die "exec: $!";
    }
    for (1 .. 200) {
        last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        Time::HiRes::sleep(0.05);
    }
    return { pid => $pid, port => $port,
             issuer => "http://127.0.0.1:$port",
             out => "$out", script => "$script" };
}

sub idp_stop {
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
        die "MockIdP pid $h->{pid} outlived ${timeout}s after SIGTERM";
    }
    open my $fh, '<', $h->{out} or die "read $h->{out}: $!";
    local $/;
    my $log = <$fh>;
    unlink $h->{out}, $h->{script};
    return $log;
}

1;
