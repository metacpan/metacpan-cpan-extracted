package Mogura::Scanner::Command;
use Mojo::Base -base;

use IO::Handle ();
use POSIX qw(setsid WNOHANG);
use Time::HiRes qw(time sleep);

sub run {
    my ($self, $arguments, %options) = @_;

    # Callers supply an absolute executable and an argument array. No command
    # is interpreted by a shell, including strings obtained from guest files.
    die 'Invalid command' unless ref $arguments eq 'ARRAY' && $arguments->[0] =~ m{\A/};
    pipe my $reader, my $writer or die "pipe: $!";
    defined $reader->blocking(0) or die "Set command output pipe to nonblocking: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        close $reader;
        eval { $self->_exec_child($arguments, $writer, \%options) };
        print STDERR $@;
        POSIX::_exit(127);
    }

    close $writer;

    my $output = '';
    my ($status, $failure);
    my $succeeded = eval {
        $status =
            $self->_wait_for_exit($pid, $reader, \$output, $arguments->[0],
            $options{timeout} // 30);
        1;
    };
    $failure = $@ || 'Command interrupted' unless $succeeded;

    if ($failure || !defined $status) {
        $self->_terminate_child($pid);
    }
    else {
        # A successful CLI must not leave descendants running after its own
        # process exits. These signals address the session created in the child.
        kill 'TERM', -$pid;
        kill 'KILL', -$pid;
    }

    # The child may have written between the last nonblocking read and reap.
    while (sysread($reader, my $buffer, 65536)) {
        $output .= $buffer;
        if (length($output) > 16 * 1024 * 1024) {
            $failure ||= 'Command output exceeds 16 MiB';
        }
        last if $failure;
    }
    close $reader;

    die $failure if $failure;
    die "Command failed ($status): $arguments->[0]\n$output" if $status;
    return $output;
}

sub _exec_child {
    my ($self, $arguments, $writer, $options) = @_;

    # A separate process group lets timeout and stop handling terminate the
    # CLI's descendants as well as its immediate process.
    setsid() >= 0 or die "setsid: $!";
    my $directory = $options->{cwd} // '/';
    chdir($directory) or die "chdir: $!";

    # Only Mogura's explicit environment reaches the CLI. HOME and cwd point
    # outside the guest, so neither tool discovers guest-controlled settings.
    %ENV = (
        PATH => '/usr/sbin:/usr/bin:/sbin:/bin',
        LANG => 'C.UTF-8',
        HOME => $directory,
        %{$options->{env} // {}},
    );
    open STDIN, '<', '/dev/null' or die "stdin: $!";
    if ($options->{stdout}) {
        open STDOUT, '>', $options->{stdout} or die "stdout: $!";
    }
    else {
        open STDOUT, '>&', $writer or die "stdout: $!";
    }
    if ($options->{log}) {
        open STDERR, '>>', $options->{log} or die "stderr: $!";
    }
    else {
        open STDERR, '>&', $writer or die "stderr: $!";
    }
    close $writer;

    exec {$arguments->[0]} @$arguments;
    die "exec $arguments->[0]: $!";
}

sub _wait_for_exit {
    my ($self, $pid, $reader, $output, $executable, $timeout) = @_;

    my $deadline = time + $timeout;
    while (1) {

        # Drain the pipe while the child is alive so verbose output cannot
        # block the child before it gets a chance to exit.
        while (sysread($reader, my $buffer, 65536)) {
            $$output .= $buffer;
            die 'Command output exceeds 16 MiB' if length($$output) > 16 * 1024 * 1024;
        }
        return $? if waitpid($pid, WNOHANG) == $pid;
        die "Command timed out: $executable" if time >= $deadline;
        sleep 0.05;
    }
}

sub _terminate_child {
    my ($self, $pid) = @_;

    kill 'TERM', -$pid;

    # A stop can arrive before setsid(), when no child process group exists.
    kill 'TERM', $pid;

    my $deadline = time + 2;
    my $reaped;
    while (time < $deadline) {
        if (waitpid($pid, WNOHANG) == $pid) {
            $reaped = 1;
            last;
        }
        sleep 0.05;
    }

    # Descendants may survive their parent's exit. Kill the group regardless,
    # but never signal an already reaped PID that the OS could have reused.
    kill 'KILL', -$pid;
    unless ($reaped) {
        kill 'KILL', $pid;
        waitpid($pid, 0);
    }
}

1;
