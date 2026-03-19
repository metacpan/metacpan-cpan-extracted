use v5.36;
package Remote::Perl;

use autodie qw(open);
use List::Util qw(min);
use IO::Select;

use Remote::Perl::Bootstrap    qw(bootstrap_payload wait_for_ready);
use Remote::Perl::ModuleServer;
use Remote::Perl::Protocol   qw(
    PROTOCOL_VERSION
    MSG_HELLO MSG_READY MSG_RUN MSG_DATA MSG_EOF
    MSG_CREDIT MSG_MOD_REQ MSG_MOD_MISSING MSG_RETURN
    MSG_SIGNAL MSG_SIGNAL_ACK
    MSG_ERROR MSG_BYE
    STREAM_CONTROL STREAM_STDIN STREAM_STDOUT STREAM_STDERR
    TMPFILE_NONE TMPFILE_AUTO TMPFILE_LINUX TMPFILE_PERL TMPFILE_NAMED
    FLAGS_WARNINGS
    encode_message encode_hello encode_credit decode_return
    encode_run
);
use Remote::Perl::Transport;

our $VERSION = '0.004';

# -- Tmpfile strategy mapping --------------------------------------------------

my %_TMPFILE_FLAG = (
    off     => TMPFILE_NONE,
    1       => TMPFILE_AUTO,
    auto    => TMPFILE_AUTO,
    linux   => TMPFILE_LINUX,
    perl    => TMPFILE_PERL,
    named   => TMPFILE_NAMED,
);

sub _tmpfile_flag($v) {
    return TMPFILE_NONE unless $v;
    die "Unknown tmpfile strategy '$v'; valid values: auto, linux, perl, named\n"
        unless exists $_TMPFILE_FLAG{$v};
    return $_TMPFILE_FLAG{$v};
}

# -- Constructor ---------------------------------------------------------------

sub new($class, %args) {
    my $self = bless {
        cmd       => $args{cmd}      // die("'cmd' is required\n"),
        window    => $args{window}   // 65_536,
        serve     => $args{serve}    // 0,
        tmpfile   => $args{tmpfile}  // 0,
        data_warn => $args{data_warn} // 0,
        _mod_srv  => ($args{serve}
                        ? Remote::Perl::ModuleServer->new(
                              inc          => $args{inc} // \@INC,
                              serve_filter => $args{serve_filter},
                          )
                        : undef),
        # set by _connect:
        _t      => undef,   # Remote::Perl::Transport
        _parser => undef,   # Remote::Perl::Protocol::Parser
        _done   => 0,
        _ready  => 0,
        # reset before each run:
        _on_stdout      => undef,
        _on_stderr      => undef,
        _returned       => 0,
        _return_code    => undef,
        _return_msg     => undef,
        _stdin_credits  => 0,
        _stdin_eof_sent => 0,
        _no_stdin       => 0,
        _stdin_str      => undef,   # plain-string stdin buffer; undef = use fh or none
    }, $class;
    $self->_connect;
    return $self;
}

# -- Internal: connect and handshake -------------------------------------------

sub _connect($self) {
    my $t = Remote::Perl::Transport->new(cmd => $self->{cmd});
    $t->connect;
    $self->{_t}      = $t;
    $self->{_parser} = Remote::Perl::Protocol::Parser->new;

    $t->write_bytes(bootstrap_payload(serve => $self->{serve}));

    # Scan for the readiness marker; any leftover bytes belong to the protocol.
    my $leftover = wait_for_ready($t->out_fh);
    $self->{_parser}->feed($leftover) if length $leftover;

    $self->_send(MSG_HELLO, STREAM_CONTROL,
        encode_hello(PROTOCOL_VERSION, $self->{window}));

    $self->_pump_until(sub { $self->{_ready} });

    unless ($self->{_ready}) {
        my $err = '';
        while ($t->stderr_ready(0.25)) {
            my $chunk = $t->read_stderr(4096);
            last unless defined $chunk && length $chunk;
            $err .= $chunk;
        }
        $err =~ s/\s+\z//;
        my $detail = length($err) ? ": $err" : '';
        die "remperl: connection failed$detail\n";
    }
}

# -- Internal: wire I/O --------------------------------------------------------

sub _send($self, $type, $stream, $body = '') {
    $self->{_t}->write_bytes(encode_message($type, $stream, $body));
}

# -- Internal: event loop ------------------------------------------------------

# Drive the event loop until $pred->() returns true or the connection closes.
# $stdin_fh: optional filehandle whose data is forwarded to STREAM_STDIN.
#   Plain-string stdin is handled via _stdin_str / _drain_stdin_str; $stdin_fh
#   is always undef in that case (strings have no real fd for select).
sub _pump_until($self, $pred, $stdin_fh = undef) {
    my $t      = $self->{_t};
    my $out_fd = fileno($t->out_fh);
    my $in_fd  = defined($stdin_fh) ? (fileno($stdin_fh) // -1) : -1;

    until ($pred->() || $self->{_done}) {
        my $sel = IO::Select->new($t->out_fh);
        if ($in_fd >= 0 && !$self->{_stdin_eof_sent}
                        && $self->{_stdin_credits} > 0) {
            $sel->add($stdin_fh);
        }

        for my $fh ($sel->can_read(1)) {
            if (fileno($fh) == $out_fd) {
                my $data = $t->read_bytes(65_536);
                unless (defined $data) { $self->{_done} = 1; last }
                $self->_dispatch($_) for $self->{_parser}->feed($data);
            }
            elsif (fileno($fh) == $in_fd) {
                $self->_forward_stdin($stdin_fh);
            }
        }
    }
}

sub _dispatch($self, $msg) {
    my ($type, $stream, $body) = @{$msg}{qw(type stream body)};

    if    ($type == MSG_READY) { $self->{_ready} = 1 }

    elsif ($type == MSG_DATA) {
        if ($stream == STREAM_STDOUT) {
            ($self->{_on_stdout} // sub {})->($body);
            $self->_send(MSG_CREDIT, STREAM_STDOUT, encode_credit(length($body)));
        }
        elsif ($stream == STREAM_STDERR) {
            ($self->{_on_stderr} // sub {})->($body);
            $self->_send(MSG_CREDIT, STREAM_STDERR, encode_credit(length($body)));
        }
    }

    elsif ($type == MSG_EOF) { }   # EOF on stdout/stderr; RETURN signals end-of-run

    elsif ($type == MSG_CREDIT) {
        if ($stream == STREAM_STDIN) {
            if ($self->{_no_stdin} && !$self->{_stdin_eof_sent}) {
                $self->_send(MSG_EOF, STREAM_STDIN);
                $self->{_stdin_eof_sent} = 1;
            }
            else {
                $self->{_stdin_credits} += unpack('N', $body);
                $self->_drain_stdin_str if defined $self->{_stdin_str};
            }
        }
    }

    elsif ($type == MSG_MOD_REQ) {
        die "remperl: serve => 1 but no ModuleServer configured\n"
            if $self->{serve} && !$self->{_mod_srv};
        my $source = ($self->{serve} && $self->{_mod_srv}) ? $self->{_mod_srv}->find($body) : undef;
        if (defined $source) {
            my $chunk = 65_536;
            for (my $off = 0; $off < length($source); $off += $chunk) {
                $self->_send(MSG_DATA, $stream, substr($source, $off, $chunk));
            }
            $self->_send(MSG_EOF, $stream);
        }
        else {
            $self->_send(MSG_MOD_MISSING, $stream);
        }
    }

    elsif ($type == MSG_SIGNAL_ACK) { }   # reserved for future unresponsive-remote detection

    elsif ($type == MSG_RETURN) {
        ($self->{_return_code}, $self->{_return_msg}) = decode_return($body);
        $self->{_returned} = 1;
    }

    elsif ($type == MSG_ERROR) { die "remperl: remote error: $body\n" }

    elsif ($type == MSG_BYE)   { $self->{_done} = 1 }
}

sub _drain_stdin_str($self) {
    while ($self->{_stdin_credits} > 0 && length($self->{_stdin_str})) {
        my $take = min(65_536, $self->{_stdin_credits}, length($self->{_stdin_str}));
        $self->_send(MSG_DATA, STREAM_STDIN, substr($self->{_stdin_str}, 0, $take, ''));
        $self->{_stdin_credits} -= $take;
    }
    if (!length($self->{_stdin_str}) && !$self->{_stdin_eof_sent}) {
        $self->_send(MSG_EOF, STREAM_STDIN);
        $self->{_stdin_eof_sent} = 1;
    }
}

sub _forward_stdin($self, $stdin_fh) {
    my $n = min(65_536, $self->{_stdin_credits});
    my $data;
    my $bytes = sysread($stdin_fh, $data, $n);
    if (!defined $bytes) {
        die "sysread stdin: $!\n";
    }
    elsif ($bytes == 0) {
        $self->_send(MSG_EOF, STREAM_STDIN);
        $self->{_stdin_eof_sent} = 1;
    }
    else {
        $self->_send(MSG_DATA, STREAM_STDIN, $data);
        $self->{_stdin_credits} -= $bytes;
    }
}

# -- Public API ----------------------------------------------------------------

# Run Perl source code on the remote.  Returns the exit code (integer).
# In list context also returns the error message (empty string on success).
#
# Options:
#   on_stdout => sub($chunk) { ... }   called for each stdout DATA chunk
#   on_stderr => sub($chunk) { ... }   called for each stderr DATA chunk
#   stdin     => $fh_or_str            filehandle or plain string to use as
#                                      remote STDIN (omit or pass undef for none)
#   args      => \@args                (optional) set remote @ARGV before running
sub run_code($self, $source, %opts) {
    $self->{_on_stdout}      = $opts{on_stdout};
    $self->{_on_stderr}      = $opts{on_stderr};
    $self->{_returned}       = 0;
    $self->{_return_code}    = undef;
    $self->{_return_msg}     = '';
    $self->{_stdin_credits}  = 0;
    $self->{_stdin_eof_sent} = 0;

    my $tmpfile  = exists $opts{tmpfile} ? $opts{tmpfile} : $self->{tmpfile};
    my $warnings = $opts{warnings} // 0;
    my $flags    = _tmpfile_flag($tmpfile) | ($warnings ? FLAGS_WARNINGS : 0);

    if (!$flags && $self->{data_warn} && $source =~ /^__DATA__(?:\r?\n|$)/m) {
        warn "remperl: script contains __DATA__ but --tmpfile is not set;"
           . " use --tmpfile for __DATA__ support\n";
    }

    my $stdin = $opts{stdin};
    my $stdin_fh;
    if (!defined $stdin) {
        $self->{_no_stdin}  = 1;
        $self->{_stdin_str} = undef;
    }
    elsif (!ref($stdin)) {
        # Plain string: buffer it; credits drive delivery in _dispatch.
        $self->{_no_stdin}  = 0;
        $self->{_stdin_str} = $stdin;
    }
    else {
        $self->{_no_stdin}  = 0;
        $self->{_stdin_str} = undef;
        $stdin_fh           = $stdin;
    }

    my @argv = $opts{args} ? @{$opts{args}} : ();
    $self->_send(MSG_RUN, STREAM_CONTROL, encode_run($flags, $source, @argv));
    $self->_pump_until(sub { $self->{_returned} }, $stdin_fh);

    return wantarray
        ? ($self->{_return_code}, $self->{_return_msg})
        : $self->{_return_code};
}

# Read a local file and run its contents as Perl source on the remote.
# Accepts the same options as run_code, including tmpfile.
sub run_file($self, $path, %opts) {
    open(my $fh, '<', $path);
    local $/;
    my $source = <$fh>;
    return $self->run_code($source, %opts);
}

# Send BYE and wait for the remote to echo it back, then close the transport.
sub disconnect($self) {
    return if $self->{_done};
    eval { $self->_send(MSG_BYE, STREAM_CONTROL) };
    $self->_pump_until(sub { $self->{_done} }) unless $self->{_done};
    $self->{_t}->disconnect;
}

sub pid($self) { $self->{_t}->pid }

# Send a signal to the remote script by name (e.g. 'INT', 'TERM').
# The remote relay process delivers it to the executor and replies with
# MSG_SIGNAL_ACK, which can later be used to detect unresponsive remotes.
sub send_signal($self, $signame) {
    $self->_send(MSG_SIGNAL, STREAM_CONTROL, $signame);
}

sub DESTROY($self) {
    eval { $self->disconnect } unless $self->{_done};
}

1;

__END__

=head1 NAME

Remote::Perl - Run Perl scripts on remote machines over any pipe transport

=head1 SYNOPSIS

Remote::Perl is available as a command line tool called L<remperl>...

  user@localhost:~$ remperl hostx -e 'print "hello from " . `hostname`'
  hello from hostx
  user@localhost:~$ remperl hostx script.pl # transfers script to hostx
  user@localhost:~$ remperl --help # for more info

...or as a library:

  use Remote::Perl;

  my $r = Remote::Perl->new(
      cmd     => ['ssh', 'hostx', 'perl'],
  );

  # Run a script file
  my ($rc, $msg) = $r->run_file('myscript.pl');
  die "failed: $msg\n" if $rc;

  # Run inline code with callbacks and arguments
  $r->run_code('print "Hello, $_\n" for @ARGV',
      args      => ['world'],
      on_stdout => sub { print STDOUT $_[0] },
      on_stderr => sub { print STDERR $_[0] },
      stdin     => \*STDIN,
  );

  $r->disconnect;

=head1 DESCRIPTION

Remote::Perl connects to a remote Perl interpreter through an arbitrary pipe
command, bootstraps a self-contained protocol client on the remote end, and
executes Perl code there.  C<STDOUT> and C<STDERR> from the remote script are
relayed in real time; local C<STDIN> is forwarded on demand.

When module serving is enabled (C<serve =E<gt> 1>), missing modules are
fetched from the local machine's C<@INC> on demand.  The remote machine needs
no pre-installed dependencies beyond a bare Perl interpreter.

Remote::Perl ships with the command line tool L<remperl> that exposes most
functionality of the module.

=head1 CONSTRUCTOR

=head2 new(%args)

  my $r = Remote::Perl->new(
      cmd       => ['ssh', 'hostx', 'perl'],   # required
      window    => 65_536,                     # flow-control window in bytes (default: 65536)
      serve     => 1,                          # enable module serving (default: 0)
      inc       => \@dirs,                     # local @INC for module serving (default: \@INC)
      tmpfile   => 'auto',                     # enable do-file mode (default: 0/disabled)
  );

Spawns the pipe command, bootstraps the remote Perl client, and performs the
protocol handshake.  Dies on failure.

C<serve> and C<inc> work together: C<serve =E<gt> 1> installs a remote
C<@INC> hook that requests modules from the local side; C<inc> supplies the
local directories to search (defaults to C<\@INC> if omitted).

C<tmpfile> enables do-file execution mode, which is required for
C<__DATA__> sections to work.  Accepted values: C<'auto'> (or C<1>) tries
the C<linux> strategy first and falls back to C<perl>; C<'linux'> uses
C<O_TMPFILE> (Linux 3.11+); C<'perl'> uses C<open('+E<gt>', undef)>;
C<'named'> uses L<File::Temp> and keeps the file until the executor
exits; C<'off'> explicitly disables (same as C<0>).  Default is C<0>
(disabled).

C<serve_filter> is an optional callback C<sub($path) { ... }> that is
called with the resolved file path of each module candidate before it is
served.  Return true to allow, false to deny.  Useful for restricting
serving to specific directories; see L<remperl/--serve-restrict-paths>
for the CLI equivalent.

C<data_warn> is used internally by the L<remperl> CLI to warn users when
a script contains C<__DATA__> but C<tmpfile> is not enabled.  Not intended
for direct use by library callers.

=head1 METHODS

=head2 run_code($source, %opts)

  my $rc          = $r->run_code($source);
  my ($rc, $msg)  = $r->run_code($source, %opts);

Executes C<$source> as Perl code on the remote side.  In scalar context
returns the exit code.  In list context also returns the error message (empty
string on clean exit, the C<die> message on failure).

Options:

=over 4

=item on_stdout => sub { my ($chunk) = @_; ... }

Called with each chunk of stdout data produced by the remote script.

=item on_stderr => sub { my ($chunk) = @_; ... }

Called with each chunk of stderr data produced by the remote script.

=item stdin => $fh_or_string

Data to supply as the remote script's C<STDIN>.  May be a filehandle (must
have a real file descriptor) or a plain string.  Omit or pass C<undef> to
supply no stdin (the remote script sees immediate EOF).

=item args => \@args

Values to place in the remote C<@ARGV> before execution.

=item tmpfile => $strategy

Per-run override for the object-level C<tmpfile> setting.  See
L</new(%args)> for accepted values.

=item warnings => $bool

Enable warnings on the remote side (sets C<$^W = 1> before running user
code), equivalent to C<perl -w>.  Default: 0.

=back

=head2 run_file($path, %opts)

  my ($rc, $msg) = $r->run_file('myscript.pl', %opts);

Reads the local file at C<$path> and runs its contents as Perl source on the
remote side.  Accepts the same options as L</run_code>.

=head2 send_signal($signame)

  $r->send_signal('INT');

Sends a signal by name to the remote script's executor process via the
protocol.  The signal is delivered regardless of the transport (SSH, Docker,
etc.) because it travels over the protocol pipe rather than as a Unix signal
to the transport process.

=head2 disconnect

  $r->disconnect;

Sends C<BYE>, waits for the remote to acknowledge, and closes the transport.
Called automatically on object destruction if not already disconnected.

=head1 SECURITY

See L<remperl/SECURITY> for security considerations.

=head1 REQUIREMENTS

Perl 5.36 or later on the local machine.  Perl 5.10 or later on the remote
machine.  No non-core modules are required on either side.

=head1 NOTES

C<__DATA__> sections require C<tmpfile> to be enabled.  Without it, code
before C<__DATA__> executes correctly but C<< <DATA> >> reads return
nothing; a warning is emitted by default.  C<__END__> stops parsing as
usual regardless of C<tmpfile> mode.

=head1 SEE ALSO

L<remperl> -- the command-line interface.

=head1 AUTHOR

Pied Crow <crow@cpan.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
