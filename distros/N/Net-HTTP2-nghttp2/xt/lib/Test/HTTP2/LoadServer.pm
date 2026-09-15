package Test::HTTP2::LoadServer;

# Starts bin/h2spec-server on a free port for the author load tests, collects
# its --stats output, and makes sure it is never left running.

use strict;
use warnings;
use Exporter 'import';
use File::Temp ();
use IO::Socket::INET;
use Time::HiRes ();

our @EXPORT_OK = qw(
    free_port
    start_server
    stop_server
    server_alive
    server_rss
    child_pids
    child_rss
    read_stats
    wait_for_stats
    sum_stats
);

# A port the kernel just handed out and we immediately gave back.
sub free_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Listen    => 1,
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or die "cannot find a free port: $!";
    my $port = $socket->sockport;
    $socket->close;
    return $port;
}

# start_server(%args): port, stats (bool), env (hashref of extra environment).
# Returns a handle for the other functions here.
sub start_server {
    my (%args) = @_;

    my $port = $args{port} || free_port();
    my $log = File::Temp->new(
        TEMPLATE => 'h2spec-server-XXXXXX',
        SUFFIX   => '.log',
        TMPDIR   => 1,
    );

    my @command = ($^X, '-Mblib', 'bin/h2spec-server');
    push @command, '--stats' if $args{stats};
    push @command, $port;

    my $pid = fork();
    die "fork failed: $!" unless defined $pid;

    unless ($pid) {
        my %env = %{ $args{env} || {} };
        $ENV{$_} = $env{$_} for keys %env;
        open STDOUT, '>&', $log or die "cannot redirect STDOUT: $!";
        open STDERR, '>&', $log or die "cannot redirect STDERR: $!";
        exec @command or die "cannot exec h2spec-server: $!";
    }

    # The File::Temp object lives in the handle, so the log survives as long as
    # the test needs it and is removed when the test process exits.
    my $server = {
        pid         => $pid,
        port        => $port,
        log         => "$log",
        log_handle  => $log,
    };

    # An END block does not run when the test process is killed by a signal, so
    # take the server with us on the signals that can reach it.
    for my $signal (qw(INT TERM HUP QUIT)) {
        $SIG{$signal} = sub {
            stop_server($server);
            $SIG{$signal} = 'DEFAULT';
            kill $signal, $$;
        };
    }

    # Wait for the listener.
    my $deadline = Time::HiRes::time() + 20;
    while (Time::HiRes::time() < $deadline) {
        my $probe = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 1,
        );
        if ($probe) {
            $probe->close;
            return $server;
        }
        die "h2spec-server exited before it listened (log $server->{log})"
            unless server_alive($server);
        Time::HiRes::sleep(0.05);
    }
    stop_server($server);
    die "h2spec-server did not listen on port $port within 20s";
}

sub server_alive {
    my ($server) = @_;
    return 0 unless $server && $server->{pid};
    return kill(0, $server->{pid}) ? 1 : 0;
}

# Resident set size in KiB, or undef when the process is gone.
sub server_rss {
    my ($server) = @_;
    my $pid = $server->{pid} or return undef;
    my $out = `ps -o rss= -p $pid 2>/dev/null`;
    return undef unless defined $out;
    $out =~ s/\s+//g;
    return length $out ? $out + 0 : undef;
}

# The connection processes this server has forked, newest last.
sub child_pids {
    my ($server) = @_;
    my $parent = $server->{pid} or return ();
    my @pids;
    for my $line (split /\n/, `ps -eo pid=,ppid= 2>/dev/null`) {
        my ($pid, $ppid) = $line =~ /\s*(\d+)\s+(\d+)/ or next;
        push @pids, $pid if $ppid == $parent;
    }
    return sort { $a <=> $b } @pids;
}

# Resident set size in KiB for one process, or undef when it is gone.
sub child_rss {
    my ($pid) = @_;
    return undef unless $pid;
    my $out = `ps -o rss= -p $pid 2>/dev/null`;
    return undef unless defined $out;
    $out =~ s/\s+//g;
    return length $out ? $out + 0 : undef;
}

# Reap the server and return its exit status, or undef if it was not running.
sub stop_server {
    my ($server, %args) = @_;
    my $signal = $args{signal} || 'TERM';
    return undef unless $server && $server->{pid};
    return $server->{status} if exists $server->{status};

    kill $signal, $server->{pid};

    my $deadline = Time::HiRes::time() + ($args{timeout} || 10);
    while (Time::HiRes::time() < $deadline) {
        my $reaped = waitpid($server->{pid}, 1);
        if ($reaped == $server->{pid}) {
            $server->{status} = $?;
            return $server->{status};
        }
        last if $reaped < 0;   # already reaped or never ours
        Time::HiRes::sleep(0.02);
    }

    kill 'KILL', $server->{pid};
    waitpid($server->{pid}, 0);
    $server->{status} = $?;
    return $server->{status};
}

# Every stats line the server has written so far, parsed.
sub read_stats {
    my ($server) = @_;
    open my $fh, '<', $server->{log} or return ();
    my @stats;
    while (my $line = <$fh>) {
        next unless $line =~ /^h2spec-server stats /;
        my %row;
        while ($line =~ /(\w+)=(\S+)/g) {
            $row{$1} = $2;
        }
        $row{frames_sent}     = _counter($row{frames_sent});
        $row{frames_not_sent} = _counter($row{frames_not_sent});
        push @stats, \%row;
    }
    close $fh;
    return @stats;
}

# Wait for at least $count stats lines, then return them all.
sub wait_for_stats {
    my ($server, $count, $timeout) = @_;
    my $deadline = Time::HiRes::time() + ($timeout || 15);
    my @stats = read_stats($server);
    while (@stats < $count && Time::HiRes::time() < $deadline) {
        Time::HiRes::sleep(0.05);
        @stats = read_stats($server);
    }
    return @stats;
}

sub _counter {
    my ($field) = @_;
    return {} if !defined $field || $field eq 'none';
    my %counter;
    for my $pair (split /;/, $field) {
        my ($key, $value) = split /:/, $pair, 2;
        $counter{$key} += $value;
    }
    return \%counter;
}

# Totals across a set of stats rows.
sub sum_stats {
    my (@stats) = @_;
    my %total = (
        connections    => scalar @stats,
        streams        => 0,
        early_resets   => 0,
        invalid_frames => 0,
        errors         => 0,
        sent           => {},
        not_sent       => {},
    );
    for my $row (@stats) {
        $total{streams}        += $row->{streams_accepted} || 0;
        $total{early_resets}   += $row->{early_resets} || 0;
        $total{invalid_frames} += $row->{invalid_frames} || 0;
        $total{errors}         += $row->{errors} || 0;
        $total{sent}{$_}     += $row->{frames_sent}{$_}     for keys %{ $row->{frames_sent} };
        $total{not_sent}{$_} += $row->{frames_not_sent}{$_} for keys %{ $row->{frames_not_sent} };
    }
    return \%total;
}

1;
