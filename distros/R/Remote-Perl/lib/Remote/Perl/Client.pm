use strict;
use warnings;
# NOTE: this file runs on the remote side and must stay compatible with Perl 5.10+.
package Remote::Perl::Client;

# Remote bootstrap client.  Sent verbatim by Bootstrap.pm and eval'd on the
# remote side.  Only uses Perl core modules.
#
# Architecture: one persistent relay process, plus one executor per RUN.
#   Client (relay)  -- owns the protocol pipe; runs the select loop permanently.
#   Executor        -- runs the user script with real STDIN/STDOUT/STDERR pipes.
#
# This split means the protocol loop is never blocked by script I/O, enabling
# real-time stdout/stderr streaming and correct signal forwarding.

use Fcntl  qw(F_SETFD FD_CLOEXEC O_RDWR);
use Socket qw(AF_UNIX SOCK_STREAM);
use POSIX  qw(WNOHANG);

# -- Save real pipe handles before any redirection -----------------------------
open(my $PIN,  '<&', \*STDIN)  or die "dup STDIN: $!\n";
open(my $POUT, '>&', \*STDOUT) or die "dup STDOUT: $!\n";
binmode($PIN); binmode($POUT);
{ my $old = select $POUT; $| = 1; select $old }
$SIG{PIPE} = 'IGNORE';

syswrite($POUT, "REMOTEPERL1\n");

# -- Constants -----------------------------------------------------------------
use constant {
    HDR             => 6,
    PROTO_VER       => 2,
    MSG_HELLO       => 0x00,   MSG_READY       => 0x01,
    MSG_RUN         => 0x10,
    MSG_DATA        => 0x20,   MSG_EOF         => 0x21,
    MSG_CREDIT      => 0x30,
    MSG_MOD_REQ     => 0x40,   MSG_MOD_MISSING => 0x41,
    MSG_RETURN      => 0x50,
    MSG_SIGNAL      => 0x60,   MSG_SIGNAL_ACK  => 0x61,
    MSG_ERROR       => 0xE0,   MSG_BYE         => 0xF0,
    S_CTRL          => 0,      S_STDIN         => 1,
    S_STDOUT        => 2,      S_STDERR        => 3,
};

# -- State ---------------------------------------------------------------------
my $pbuf        = '';
my %sc          = ();   # send credits: stream_id => bytes remaining
my $window      = 65536;
my $done        = 0;
my $next_stream = 4;

# -- Wire I/O ------------------------------------------------------------------

# Write bytes to the protocol pipe.
sub _write {
    my ($bytes) = @_;
    my ($total, $off) = (length($bytes), 0);
    while ($off < $total) {
        my $n = syswrite($POUT, $bytes, $total - $off, $off);
        die "syswrite: $!\n" unless defined $n;
        $off += $n;
    }
}

sub _send {
    my ($type, $stream, $body) = @_;
    $body //= '';
    _write(pack('CCN', $type, $stream, length($body)) . $body);
}

# Write all bytes to an arbitrary filehandle (pipes, sockets).
sub _write_fh {
    my ($fh, $bytes) = @_;
    my ($total, $off) = (length($bytes), 0);
    while ($off < $total) {
        my $n = syswrite($fh, $bytes, $total - $off, $off);
        die "syswrite fh: $!\n" unless defined $n;
        $off += $n;
    }
}

# Blocking read of exactly $n bytes from $fh.  Returns undef on EOF.
sub _read_fixed {
    my ($fh, $n) = @_;
    my $buf = '';
    while (length($buf) < $n) {
        my $got = sysread($fh, my $chunk, $n - length($buf));
        die "sysread fh: $!\n" unless defined $got;
        return undef unless $got;
        $buf .= $chunk;
    }
    return $buf;
}

# -- Protocol parsing ----------------------------------------------------------

sub _pump {
    my $block = @_ ? $_[0] : 1;
    my $rin = '';
    vec($rin, fileno($PIN), 1) = 1;
    return unless select(my $r = $rin, undef, undef, $block ? undef : 0) > 0;
    my $n = sysread($PIN, my $data, 65536);
    die "sysread: $!\n" unless defined $n;
    unless ($n) { $done = 1; return }
    $pbuf .= $data;
    _drain_dispatch();
}

sub _drain_dispatch {
    while (length($pbuf) >= HDR) {
        my ($type, $stream, $len) = unpack('CCN', $pbuf);
        last if length($pbuf) < HDR + $len;
        substr($pbuf, 0, HDR, '');
        my $body = $len ? substr($pbuf, 0, $len, '') : '';
        _dispatch($type, $stream, $body);
    }
}

# -- Pre-fork dispatcher (handshake + waiting for RUN) -------------------------
my ($run_flags, $run_source, @run_args);

sub _decode_run {
    my ($body) = @_;
    my $off   = 0;
    my $flags = unpack('C', substr($body, $off, 1)); $off += 1;
    my $argc  = unpack('N', substr($body, $off, 4)); $off += 4;
    my @argv;
    for (1 .. $argc) {
        my $len = unpack('N', substr($body, $off, 4)); $off += 4;
        push @argv, substr($body, $off, $len); $off += $len;
    }
    return ($flags, substr($body, $off), @argv);
}

sub _dispatch {
    my ($type, $stream, $body) = @_;
    if    ($type == MSG_CREDIT) { $sc{$stream} = ($sc{$stream}//0) + unpack('N', $body) }
    elsif ($type == MSG_RUN)    { ($run_flags, $run_source, @run_args) = _decode_run($body) }
    elsif ($type == MSG_BYE)    { $done = 1 }
    elsif ($type == MSG_ERROR)  { warn "remperl error: $body\n"; $done = 1 }
}

sub _read_raw_message {
    while (length($pbuf) < HDR) {
        my $n = sysread($PIN, my $data, 65536);
        die "sysread: $!\n" unless defined $n;
        die "EOF waiting for message\n" unless $n;
        $pbuf .= $data;
    }
    my ($type, $stream, $len) = unpack('CCN', $pbuf);
    while (length($pbuf) < HDR + $len) {
        my $n = sysread($PIN, my $data, 65536);
        die "sysread: $!\n" unless defined $n;
        die "EOF waiting for message body\n" unless $n;
        $pbuf .= $data;
    }
    substr($pbuf, 0, HDR, '');
    my $body = $len ? substr($pbuf, 0, $len, '') : '';
    return ($type, $stream, $body);
}

# -- Handshake -----------------------------------------------------------------
{
    my ($type, undef, $body) = _read_raw_message();
    die sprintf("Expected HELLO(0x00), got 0x%02x\n", $type) unless $type == MSG_HELLO;
    die sprintf("Malformed HELLO: expected 5 bytes, got %d\n", length($body))
        unless length($body) >= 5;
    my ($ver, $win) = unpack('CN', $body);
    die "Protocol version mismatch: got $ver, expected " . PROTO_VER . "\n"
        unless $ver == PROTO_VER;
    $window = $win;
    $sc{$_} = $window for S_CTRL, S_STDOUT, S_STDERR;
    _send(MSG_READY, S_CTRL);
}

# -- Main loop: handle successive RUN commands on the same connection ----------
until ($done) {
    $run_flags  = 0;
    $run_source = undef;
    @run_args   = ();
    _pump(1) until defined $run_source || $done;
    last if $done;
    _do_run($run_flags, $run_source, @run_args);
}
_send(MSG_BYE, S_CTRL);

# -- Temp file strategies for do-file execution --------------------------------

# Returns ($path, $fh): $path is undef for anon strategies (use /proc/self/fd/N).
# $fh must stay alive for the lifetime of the executor (keeps anon inode open;
# for NAMED, File::Temp destructor removes the file only on global destruction,
# which runs after END blocks).
sub _make_tmpfile {
    my ($source, $strategy) = @_;
    if ($strategy == 1 || $strategy == 2) {
        # Try O_TMPFILE: anonymous inode, never has a directory entry.
        my $O_TMPFILE = eval { Fcntl::O_TMPFILE() };
        if (defined $O_TMPFILE) {
            if (sysopen(my $fh, '/tmp', O_RDWR | $O_TMPFILE)) {
                print $fh $source;
                seek $fh, 0, 0;
                return (undef, $fh);
            }
        }
        return _make_tmpfile($source, 3) if $strategy == 1;   # auto: try perl
        die "tmpfile strategy 'linux' unavailable on this system\n";
    }
    if ($strategy == 3) {
        open(my $fh, '+>', undef) or die "open anon tmpfile: $!\n";
        print $fh $source;
        seek $fh, 0, 0;
        return (undef, $fh);
    }
    if ($strategy == 4) {
        require File::Temp;
        my $fh = File::Temp->new(UNLINK => 1);
        print $fh $source;
        $fh->flush;
        return ($fh->filename, $fh);
    }
    die "unknown tmpfile strategy: $strategy\n";
}

# -- Per-run entry point -------------------------------------------------------
sub _do_run {
    my ($flags, $source, @args) = @_;
    pipe(my $stdin_r,  my $stdin_w)  or die "pipe stdin: $!\n";
    pipe(my $stdout_r, my $stdout_w) or die "pipe stdout: $!\n";
    pipe(my $stderr_r, my $stderr_w) or die "pipe stderr: $!\n";
    pipe(my $result_r, my $result_w) or die "pipe result: $!\n";
    socketpair(my $mod_c, my $mod_e, AF_UNIX, SOCK_STREAM, 0)
        or die "socketpair: $!\n";
    binmode($_) for $stdin_r,  $stdin_w,
                    $stdout_r, $stdout_w,
                    $stderr_r, $stderr_w,
                    $result_r, $result_w,
                    $mod_c,    $mod_e;

    my $exec_pid = fork() // die "fork: $!\n";

    # Extract warnings bit before using flags for tmpfile strategy.
    my $do_warnings = $flags & 0x08;
    $flags &= 0x07;

    if ($exec_pid == 0) {
        # === EXECUTOR (child) =================================================
        close($_) for $stdin_w, $stdout_r, $stderr_r, $result_r, $mod_c;

        open(STDIN,  '<&', $stdin_r)  or die "dup stdin: $!\n";
        open(STDOUT, '>&', $stdout_w) or die "dup stdout: $!\n";
        open(STDERR, '>&', $stderr_w) or die "dup stderr: $!\n";
        $| = 1;
        { my $old = select STDERR; $| = 1; select $old }
        close($_) for $stdin_r, $stdout_w, $stderr_w;

        # Mark internal fds close-on-exec so they don't leak into any child
        # processes spawned by user code.
        fcntl($result_w, F_SETFD, FD_CLOEXEC);
        fcntl($mod_e,    F_SETFD, FD_CLOEXEC);

        # Enable warnings if requested (mirrors perl -w).
        $^W = 1 if $do_warnings;

        # Install the @INC hook if module serving is enabled.
        our $REMOTE_PERL_SERVE //= 0;

        if ($REMOTE_PERL_SERVE) {
            my $inc_hook = sub {
                my (undef, $filename) = @_;
                _write_fh($mod_e, pack('N', length($filename)) . $filename);
                my $status = _read_fixed($mod_e, 1) // return undef;
                return undef if unpack('C', $status);   # MOD_MISSING
                my $src_len = unpack('N', _read_fixed($mod_e, 4) // return undef);
                my $src     = _read_fixed($mod_e, $src_len)       // return undef;
                open(my $fh, '<', \$src) or die "scalar open: $!\n";
                return $fh;
            };
            push @INC, $inc_hook;
        }

        $SIG{PIPE} = 'DEFAULT';
        @ARGV = @args;

        my $eval_err;
        if ($flags == 0) {
            # Strip all pragmas we enable (strict, warnings) and reset to
            # package main so Client.pm's imports are not visible —
            # matching the clean state of `perl -e`.
            # When $do_warnings is set, omit `no warnings` so $^W takes effect.
            if ($do_warnings) {
                { no strict; package main; eval $source }
            }
            else {
                { no strict; no warnings; package main; eval $source }
            }
            $eval_err = $@;
        }
        else {
            my ($path, $tmpfh) = _make_tmpfile($source, $flags);
            my $dopath = defined $path ? $path : "/proc/self/fd/" . fileno($tmpfh);
            # Same pragma stripping as eval mode: do FILE inherits %^H from its
            # calling scope, so strict/warnings must be cleared here.
            # Capture $@ inside the block: do FILE sets it for compile errors but
            # does not throw, so eval BLOCK would otherwise clear it on exit.
            if ($do_warnings) {
                { no strict; package main;
                  eval { do $dopath; $eval_err = $@ if $@ };
                  $eval_err //= $@ if $@;
                }
            }
            else {
                { no strict; no warnings; package main;
                  eval { do $dopath; $eval_err = $@ if $@ };
                  $eval_err //= $@ if $@;
                }
            }
        }

        # Write die message (if any) and close the result pipe before output
        # streams, so the relay can read it by the time stdout/stderr reach EOF.
        if ($eval_err) {
            _write_fh($result_w, pack('N', length($eval_err)) . $eval_err);
        }
        close($result_w);
        close($mod_e);
        close(STDOUT);
        close(STDERR);
        exit($eval_err ? 255 : 0);
    }

    # === CLIENT / RELAY (parent) ==============================================
    close($_) for $stdin_r, $stdout_w, $stderr_w, $result_w, $mod_e;

    # Grant stdin credits so the local side may send data.
    _send(MSG_CREDIT, S_STDIN, pack('N', $window));

    my $die_msg = _relay($exec_pid, $stdin_w, $stdout_r, $stderr_r, $result_r, $mod_c);

    waitpid($exec_pid, 0);
    my $exit_code = ($? & 0x7F) ? 1 : (($? >> 8) & 0xFF);
    _send(MSG_RETURN, S_CTRL, pack('C', $exit_code) . $die_msg);
}

# -- Relay loop ----------------------------------------------------------------

# Send as much of $$bufref as credits allow on $stream.
sub _flush_buf {
    my ($stream, $bufref) = @_;
    while (($sc{$stream}//0) > 0 && length($$bufref)) {
        my $take = ($sc{$stream} < length($$bufref)) ? $sc{$stream} : length($$bufref);
        _send(MSG_DATA, $stream, substr($$bufref, 0, $take, ''));
        $sc{$stream} -= $take;
    }
}

sub _relay {
    my ($exec_pid, $stdin_w, $stdout_r, $stderr_r, $result_r, $mod_c) = @_;
    my ($stdout_eof, $stderr_eof, $stdin_w_closed, $mod_c_eof) = (0, 0, 0, 0);
    my ($stdout_buf, $stderr_buf) = ('', '');

    # At most one module request in flight at a time: executor blocks until answered.
    my ($mod_stream, %mod_src, %mod_fin, %mod_miss);

    RELAY: until ($stdout_eof && $stderr_eof && !length($stdout_buf) && !length($stderr_buf)) {
        my $rin = '';
        vec($rin, fileno($PIN),      1) = 1;
        vec($rin, fileno($stdout_r), 1) = 1 unless $stdout_eof;
        vec($rin, fileno($stderr_r), 1) = 1 unless $stderr_eof;
        # Watch for new module requests only when none is in flight.
        vec($rin, fileno($mod_c),    1) = 1 unless $mod_c_eof || defined $mod_stream;

        select(my $r = $rin, undef, undef, undef);

        # -- Protocol pipe -----------------------------------------------------
        if (vec($r, fileno($PIN), 1)) {
            my $n = sysread($PIN, my $data, 65536);
            unless ($n) { $done = 1; last RELAY }
            $pbuf .= $data;

            while (length($pbuf) >= HDR) {
                my ($type, $stream, $len) = unpack('CCN', $pbuf);
                last if length($pbuf) < HDR + $len;
                substr($pbuf, 0, HDR, '');
                my $body = $len ? substr($pbuf, 0, $len, '') : '';

                if ($type == MSG_CREDIT) {
                    $sc{$stream} = ($sc{$stream}//0) + unpack('N', $body);
                    _flush_buf(S_STDOUT, \$stdout_buf) if $stream == S_STDOUT;
                    _flush_buf(S_STDERR, \$stderr_buf) if $stream == S_STDERR;
                }
                elsif ($type == MSG_DATA && $stream == S_STDIN && !$stdin_w_closed) {
                    my $n = length($body);
                    eval { _write_fh($stdin_w, $body) };
                    if ($@) { close($stdin_w); $stdin_w_closed = 1 }
                    # Re-grant credits for the bytes just delivered so the
                    # local side can send more stdin beyond the initial window.
                    else     { _send(MSG_CREDIT, S_STDIN, pack('N', $n)) }
                }
                elsif ($type == MSG_EOF && $stream == S_STDIN && !$stdin_w_closed) {
                    close($stdin_w);
                    $stdin_w_closed = 1;
                }
                elsif ($type == MSG_SIGNAL) {
                    _send(MSG_SIGNAL_ACK, S_CTRL, $body);
                    kill($body, $exec_pid);
                }
                elsif ($type == MSG_ERROR) {
                    warn "remperl error: $body\n";
                    kill('TERM', $exec_pid);
                    $done = 1; last RELAY;
                }
                elsif ($type == MSG_BYE) {
                    $done = 1; last RELAY;
                }
                # Module response from the local side.
                elsif (defined $mod_stream && $stream == $mod_stream) {
                    $mod_src{$mod_stream} .= $body if $type == MSG_DATA;
                    $mod_fin{$mod_stream}  = 1     if $type == MSG_EOF;
                    $mod_miss{$mod_stream} = 1     if $type == MSG_MOD_MISSING;
                }
            }

            # Forward completed module response to the executor.
            if (defined $mod_stream
                    && ($mod_fin{$mod_stream} || $mod_miss{$mod_stream})) {
                if ($mod_fin{$mod_stream}) {
                    my $src = $mod_src{$mod_stream};
                    eval { _write_fh($mod_c, pack('CN', 0, length($src)) . $src) };
                    $mod_c_eof = 1 if $@;
                } else {
                    eval { _write_fh($mod_c, pack('C', 1)) };
                    $mod_c_eof = 1 if $@;
                }
                delete $mod_src{$mod_stream};
                delete $mod_fin{$mod_stream};
                delete $mod_miss{$mod_stream};
                $mod_stream = undef;
            }
        }

        # -- Executor stdout ---------------------------------------------------
        if (!$stdout_eof && vec($r, fileno($stdout_r), 1)) {
            my $n = sysread($stdout_r, my $data, 65536);
            if ($n) {
                $stdout_buf .= $data;
                _flush_buf(S_STDOUT, \$stdout_buf);
            } else {
                _flush_buf(S_STDOUT, \$stdout_buf);
                _send(MSG_EOF, S_STDOUT);
                $stdout_eof = 1;
            }
        }

        # -- Executor stderr ---------------------------------------------------
        if (!$stderr_eof && vec($r, fileno($stderr_r), 1)) {
            my $n = sysread($stderr_r, my $data, 65536);
            if ($n) {
                $stderr_buf .= $data;
                _flush_buf(S_STDERR, \$stderr_buf);
            } else {
                _flush_buf(S_STDERR, \$stderr_buf);
                _send(MSG_EOF, S_STDERR);
                $stderr_eof = 1;
            }
        }

        # -- Module socket: new request from executor --------------------------
        if (!$mod_c_eof && !defined $mod_stream && vec($r, fileno($mod_c), 1)) {
            my $hdr = _read_fixed($mod_c, 4);
            if (!defined $hdr) {
                $mod_c_eof = 1;   # executor closed its end; stop watching
            }
            else {
                my $filename = _read_fixed($mod_c, unpack('N', $hdr)) // do { $mod_c_eof = 1; next };
                $mod_stream              = $next_stream++;
                $mod_src{$mod_stream}    = '';
                $mod_fin{$mod_stream}    = 0;
                $mod_miss{$mod_stream}   = 0;
                _send(MSG_MOD_REQ, $mod_stream, $filename);
            }
        }
    }

    # Clean up if the connection died before the run completed.
    unless ($stdout_eof && $stderr_eof) {
        kill('TERM', $exec_pid);
    }
    close($stdin_w) unless $stdin_w_closed;

    # Read die message from the result pipe.  The executor writes the message
    # (if any) and closes result_w before closing stdout/stderr, so by the time
    # we reach here the data is already in the kernel pipe buffer.
    my $die_msg = '';
    my $hdr = _read_fixed($result_r, 4);
    if (defined $hdr) {
        my $len = unpack('N', $hdr);
        $die_msg = $len ? (_read_fixed($result_r, $len) // '') : '';
    }

    return $die_msg;
}

1;
