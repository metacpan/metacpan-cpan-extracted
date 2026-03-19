use v5.36;
package Remote::Perl::Transport;
our $VERSION = '0.004';

use autodie qw(open close);
use IO::Select;
use POSIX qw(WNOHANG);

# Wraps a bidirectional pipe to a child process.
#
# The child's stdin  <- we write protocol bytes
# The child's stdout -> we read  protocol bytes
# The child's stderr -> we read  for debug/error logging (separate channel)
#
# All handles are set to binmode (raw bytes, no encoding layers).

sub new($class, %args) {
    # cmd => arrayref of command + arguments (no shell expansion)
    return bless {
        cmd     => $args{cmd},
        pid     => undef,
        in_fh   => undef,   # write end  -> child stdin
        out_fh  => undef,   # read end   <- child stdout
        err_fh  => undef,   # read end   <- child stderr
    }, $class;
}

sub connect($self) {
    $SIG{PIPE} = 'IGNORE';

    # We fork+exec manually instead of using open3 so we can call setpgrp()
    # in the child.  This puts the transport process (e.g. ssh) in its own
    # process group, preventing terminal-generated signals (Ctrl-C -> SIGINT)
    # from reaching it directly.  Signals are instead forwarded through the
    # protocol by the parent's signal handlers.
    pipe(my $child_in_r,  my $child_in_w)  or die "pipe: $!\n";
    pipe(my $child_out_r, my $child_out_w) or die "pipe: $!\n";
    pipe(my $child_err_r, my $child_err_w) or die "pipe: $!\n";

    my $pid = fork() // die "fork: $!\n";

    if ($pid == 0) {
        # Child: new process group so parent's signals don't reach us.
        setpgrp(0, 0);

        close($child_in_w);
        close($child_out_r);
        close($child_err_r);

        open(STDIN,  '<&', $child_in_r)  or die "dup stdin: $!\n";
        open(STDOUT, '>&', $child_out_w) or die "dup stdout: $!\n";
        open(STDERR, '>&', $child_err_w) or die "dup stderr: $!\n";
        close($_) for $child_in_r, $child_out_w, $child_err_w;

        exec(@{ $self->{cmd} }) or die "exec: $!\n";
    }

    close($child_in_r);
    close($child_out_w);
    close($child_err_w);

    binmode($child_in_w);
    binmode($child_out_r);
    binmode($child_err_r);

    $self->{pid}    = $pid;
    $self->{in_fh}  = $child_in_w;
    $self->{out_fh} = $child_out_r;
    $self->{err_fh} = $child_err_r;
}

# Write raw bytes to child stdin.  Returns number of bytes written.
sub write_bytes($self, $data) {
    my $total = length($data);
    my $written = 0;
    while ($written < $total) {
        my $n = syswrite($self->{in_fh}, $data, $total - $written, $written);
        die "syswrite: $!\n" unless defined $n;
        $written += $n;
    }
    return $written;
}

# Read up to $len bytes from child stdout.
# Returns undef on EOF, dies on error.
sub read_bytes($self, $len) {
    my $data;
    my $n = sysread($self->{out_fh}, $data, $len);
    die "sysread: $!\n" unless defined $n;
    return if $n == 0;   # EOF
    return $data;
}

# Read up to $len bytes from child stderr (non-blocking).
# Returns '' if nothing available, undef on EOF.
sub read_stderr($self, $len = 4096) {
    return '' unless $self->stderr_ready(0);
    my $data;
    my $n = sysread($self->{err_fh}, $data, $len);
    die "sysread stderr: $!\n" unless defined $n;
    return if $n == 0;
    return $data;
}

# Return true if child stderr has data ready within $timeout seconds.
sub stderr_ready($self, $timeout = 0) {
    return IO::Select->new($self->{err_fh})->can_read($timeout);
}

# Expose raw filehandle and pid for callers building their own IO::Select sets.
sub out_fh($self)  { $self->{out_fh} }
sub pid($self)     { $self->{pid} }

# Close stdin (signals EOF to child) and wait for it to exit.
sub disconnect($self) {
    if ($self->{in_fh}) {
        close($self->{in_fh});
        $self->{in_fh} = undef;
    }
    $self->_wait_for_child;
}

sub _wait_for_child($self) {
    return unless $self->{pid};
    my $pid = $self->{pid};

    # Poll for up to 5 seconds, then escalate.
    my $deadline = time + 5;
    while (time < $deadline) {
        my $result = waitpid($pid, WNOHANG);
        if ($result == $pid) {
            $self->{pid} = undef;
            return $?;
        }
        select(undef, undef, undef, 0.05);   # 50 ms sleep
    }
    kill('TERM', $pid);
    sleep 1;
    waitpid($pid, WNOHANG);
    $self->{pid} = undef;
}

sub DESTROY($self) {
    if ($self->{in_fh}) {
        close($self->{in_fh});
        $self->{in_fh} = undef;
    }
    $self->_wait_for_child if $self->{pid};
}

1;

__END__

=head1 NAME

Remote::Perl::Transport - spawn and manage the remote process (internal part of Remote::Perl)

=head1 DESCRIPTION

Forks and execs the configured pipe command (e.g. C<ssh host perl>), wires up
stdin/stdout/stderr pipes in binary mode, and exposes read/write/disconnect
operations used by the protocol layer.

=head1 INTERNAL

Not public API.  This is an internal module used by L<Remote::Perl>; its interface
may change without notice.

=cut
