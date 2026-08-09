package PQSpawn;

# Spawning punk-queue as a real subprocess, for the worker and CLI tests.
#
# Tests never fork perl themselves: a forked test process carries the
# harness's END blocks and buffered TAP with it, and both fire twice. The
# CLI process is the thing under test anyway.

use 5.010;
use strict;
use warnings;
use Exporter 'import';
use FindBin ();
use File::Temp ();
use Config ();

our @EXPORT = qw(pq_run pq_start pq_finish task_app);

my $BIN = "$FindBin::Bin/../bin/punk-queue";

# Run punk-queue @args to completion. Returns (exit_code, stdout_lines).
# %opts: env => {..} merged for the child only.
sub pq_run {
    my ($args, %opts) = @_;
    my $out = File::Temp->new(TEMPLATE => 'pqoutXXXXXX', TMPDIR => 1);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $ENV{$_} = $opts{env}{$_} for keys %{ $opts{env} || {} };
        open STDOUT, '>&', $out or die "redirect: $!";
        open STDERR, '>&', $out or die "redirect: $!";
        exec $^X, '-Mblib', $BIN, @$args
            or die "exec: $!";
    }
    waitpid $pid, 0;
    my $code = $? >> 8;
    open my $fh, '<', "$out" or die "read $out: $!";
    my @lines = <$fh>;
    return ($code, \@lines);
}

# Start punk-queue in the background. Returns { pid, out (path) }.
sub pq_start {
    my ($args, %opts) = @_;
    my $out = File::Temp->new(TEMPLATE => 'pqoutXXXXXX', TMPDIR => 1,
                              UNLINK => 0);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $ENV{$_} = $opts{env}{$_} for keys %{ $opts{env} || {} };
        open STDOUT, '>&', $out or die "redirect: $!";
        open STDERR, '>&', $out or die "redirect: $!";
        exec $^X, '-Mblib', $BIN, @$args
            or die "exec: $!";
    }
    return { pid => $pid, out => "$out" };
}

# Signal and reap a pq_start handle. Returns (exit_code, stdout_lines).
sub pq_finish {
    my ($h, $sig, %opts) = @_;
    my $timeout = $opts{timeout} // 30;
    kill $sig, $h->{pid} if $sig;
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
        die "punk-queue pid $h->{pid} outlived ${timeout}s after SIG$sig";
    }
    my $code = $? >> 8;
    open my $fh, '<', $h->{out} or die "read $h->{out}: $!";
    my @lines = <$fh>;
    unlink $h->{out};
    return ($code, \@lines);
}

# Write an --app file: a queue on $dsn with the standard test tasks.
# $extra is verbatim perl appended before the queue is returned.
sub task_app {
    my ($dsn, $extra) = @_;
    my $file = File::Temp->new(TEMPLATE => 'pqappXXXXXX', TMPDIR => 1,
                               SUFFIX => '.pl', UNLINK => 0);
    $extra //= '';
    print {$file} <<"EOF";
use strict; use warnings;
use Punk::Queue;
my \$q = Punk::Queue->new(dsn => q{$dsn});
\$q->task(add   => sub { my (\$job, \$a, \$b) = \@_; \$a + \$b });
\$q->task(boom  => sub { die "task exploded\\n" });
\$q->task(bail  => sub { exit 7 });
\$q->task(snooze => sub { sleep \$_[1] || 1; 'woke' });
$extra
\$q;
EOF
    close $file;
    return "$file";
}

1;
