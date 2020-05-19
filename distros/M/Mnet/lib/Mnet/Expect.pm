package Mnet::Expect;

=head1 NAME

Mnet::Expect - Create Expect objects with Mnet::Log support

=head1 SYNOPSIS

    # refer to SEE ALSO section for other Mnet::Expect modules
    use Mnet::Expect;

    # spawn Expect telnet process connected to specified host
    my $expect = Mnet::Expect->new({ spawn => "telnet 1.2.3.4" });

    # access underlying Expect methods, refer to perldoc Expect
    $expect->expect->send("ls\r");

    # gracefully close spawned Expect process
    $expect->close;

=head1 DESCRIPTION

Mnet::Expect can be used to spawn L<Expect> processes, which can be used
to programmatically control interactive terminal sessions, with support for
L<Mnet> options and logging.

Refer to the perl L<Expect> module for more information. Also refer to the
L<Mnet::Expect::Cli> and L<Mnet::Expect::Cli::Ios> modules.

=head1 METHODS

Mnet::Expect implements the methods listed below.

=cut

# required modules
#   importing Expect namespace conflicted with expect sub here
use warnings;
use strict;
use parent qw( Mnet::Log::Conditional );
use Carp;
use Errno;
use Expect();
use Mnet::Dump;
use Mnet::Opts::Cli::Cache;



sub new {

=head2 new

    $expect = Mnet::Expect->new(\%opts)

This method can be used to create new Mnet::Expect objects.

The following input opts may be specified:

    log_expect  default session debug, refer to log_expect method
    log_id      refer to perldoc Mnet::Log new method
    raw_pty     undef, can be set 0 or 1, refer to perldoc Expect
    spawn       command and args array ref, or space separated string
    winsize     specify session rows and columns, default 99999x999

An error is issued if there are spawn problems.

For example, the following will spawn an telnet expect session to a device:

    my $expect = Mnet::Expect->new({ spawn => "telnet 1.2.3.4" });

Note that all connected session activity is logged for debugging, refer to
the L<Mnet::Log> module for more information.

=cut

    # read input class and options hash ref merged with cli options
    my $class = shift // croak("missing class arg");
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # create log object with input opts hash, cli opts, and pragmas in effect
    #   ensures we can log correctly even if inherited object creation fails
    my $log = Mnet::Log::Conditional->new($opts);
    $log->debug("new starting");

    # create hash that will become new object from input opts hash
    my $self = $opts;

    # note default options for this class
    #   includes recognized input opts and cli opts for this object
    #   the following keys starting with underscore are used internally:
    #       _expect     => spawned Expect object, refer to Mnet::Expect->expect
    #       _log_filter => set to password text to filter from debug log once
    #       _no_spawn   => set true to skip spawn, used by sub-modules' replay
    #   in addition refer to perldoc for input opts and Mnet::Log0->new opts
    #   update perldoc for this sub with changes
    my $defaults = {
        debug       => $opts->{debug},
        _expect     => undef,
        _log_filter => undef,
        log_id      => $opts->{log_id},
        log_expect  => "debug",
        _no_spawn   => undef,
        quiet       => $opts->{quiet},
        raw_pty     => undef,
        silent      => $opts->{silent},
        spawn       => undef,
        winsize     => "99999x999",
    };

    # update future object $self hash with default opts
    foreach my $opt (sort keys %$defaults) {
        $self->{$opt} = $defaults->{$opt} if not exists $self->{$opt};
    }

    # debug opts set here, hide internal opts starting w/underscore
    foreach my $opt (sort keys %$self) {
        if ($opt !~ /^_/) {
            my $value = Mnet::Dump::line($self->{$opt});
            $log->debug("new opt $opt = $value");
        }
    }

    # bless new object
    bless $self, $class;

    # call to log_expect to ensure that log_level is valid
    $self->log_expect($self->{log_expect});

    # return undef if Expect spawn does not succeed
    $self->debug("new calling spawn");
    if (not $self->spawn) {
        $self->debug("new finished, spawn failed, returning undef");
        return undef;
    }

    # finished new method, return Mnet::Expect object
    $self->debug("new finished, returning $self");
    return $self;
}



sub spawn {

# $ok = $self->spawn
# purpose: used to spawn Expect object
# $ok: set true on success, false on failure

    # read input object
    my $self = shift;
    $self->debug("spawn starting");

    # return true if _no_spawn is set
    #   this is used for replay from sub-modules
    #   this avoids interference with replay in the module
    if ($self->{_no_spawn}) {
        $self->debug("spawn skipped for _no_spawn");
        return 1;
    }

    # error if spawn option was not set
    croak("missing spawn option") if not defined $self->{spawn};

    # conditionally load perl Expect module and create new expect object
    #   we are only loading the Expect module if this method is called
    #   require is used so as to not import anything into this namespace
    eval("require Expect; 1") or croak("missing Expect perl module");
    $self->{_expect} = Expect->new;

    # set raw_pty for expect session if defined as an input option
    $self->{_expect}->raw_pty($self->{raw_pty}) if defined $self->{raw_pty};

    # set default window size for expect tty session
    #   this defaults to a large value to minimize pagination and line wrapping
    #   IO::Tty::Constant module is pulled into namespace when Expect is used
    croak("bad winsize $self->{winsize}")
        if $self->{winsize} !~ /^(\d+)x(\d+)$/;
    my $tiocswinsz = IO::Tty::Constant::TIOCSWINSZ();
    my $winsize_pack = pack('SSSS', $1, $2, 0, 0);
    ioctl($self->expect->slave, $tiocswinsz, $winsize_pack);

    # set Mnet::Expect->log method for logging
    #   disable expect stdout logging
    $self->expect->log_stdout(0);
    $self->expect->log_file(sub { $self->_log(shift) });

    # note spawn command and arg list
    #   this can be specified as a list reference or a space-separated string
    my @spawn = ();
    @spawn = @{$self->{spawn}} if ref $self->{spawn};
    @spawn = split(/\s/, $self->{spawn}) if not ref $self->{spawn};
    $self->debug("spawn arg: $_") foreach @spawn;

    # call Expect spawn method
    #   disable Mnet::Tee stdout/stderr ties if not Mnet::Tee is loaded
    #   stdout/stderr ties cause spawn problems, but can be re-enabled after
    #   init global Mnet::Expect error to undef, set on expect spawn failures
    if ($INC{'Mnet/Tee.pm'}) {
        Mnet::Tee::tie_disable();
        $self->debug("spawn calling Expect module spawm method");
        $self->fatal("spawn error, $!") if not $self->expect->spawn(@spawn);
        Mnet::Tee::tie_enable();
    } else {
        $self->fatal("spawn error, $!") if not $self->expect->spawn(@spawn);
    }

    # note spawn process id
    $self->debug("spawn pid ".$self->expect->pid);

    # finished spawn method, return true for success
    $self->debug("spawn finished, returning true");
    return 1;
}



sub close {

=head2 close

    $expect->close

Attempt to call hard_close for the current Mnet::Expect objects L<Expect>
session, and send a kill signal if the process still exists.

The L<Expect> object associated with the current Mnet::Expect object will be
set to undefined. Refer also to the expect method documented below.

=cut

    # read input object
    my $self = shift;
    $self->debug("close starting");

    # return if expect object no longer defined
    if (not defined $self->expect) {
        $self->debug("close finished, expect not defined");
        return;
    }

    # note process id of spawned expect command
    my $spawned_pid = $self->expect->pid;

    # return if there's no expect process id
    if (not defined $spawned_pid) {
        $self->debug("close finished, no expect pid");
        $self->{_expect} = undef;
        return;
    }

    # continue processing
    $self->debug("close proceeding for pid $spawned_pid");

    # usage: $result = _close_confirmed($self, $label, $spawned_pid)
    #   kill(0,$pid) is true if pid signalable, Errno::ESRCH if not found
    #   purpose: return true if $spawned_pid is gone, $label used for debug
    #   note: if result is true then expect object will have been set undefined
    sub _close_confirmed {
        my ($self, $label, $spawned_pid) = (shift, shift, shift);
        if (not kill(0, $spawned_pid)) {
            if ($! == Errno::ESRCH) {
                $self->debug("close finished, $label confirmed");
                $self->{_expect} = undef;
                return 1;
            }
            $self->debug("close pid check error after $label, $!");
        }
        return 0;
    }

    # call hard close
    #   ignore int and term signals to avoid hung processes
    $self->debug("close calling hard_close");
    eval {
        local $SIG{INT} = "IGNORE";
        local $SIG{TERM} = "IGNORE";
        $self->expect->hard_close;
    };
    return if _close_confirmed($self, "hard_close", $spawned_pid);

    # if hard_close failed then send kill -9 signal
    $self->debug("close sending kill signal");
    kill(9, $spawned_pid);
    return if _close_confirmed($self, "kill", $spawned_pid);

    # undefine expect object since nothing else worked
    $self->{_expect} = undef;

    # finished close method
    $self->debug("close finished, expect undef after kill");
    return;
}



sub expect {

=head2 expect

    $expect->expect

Returns the underlying expect object used by this module, for access to fetures
that may not be supported directly by Mnet::Expect modules. Refer to the
L<Expect> module for more information.

=cut

    # return underlying expect object
    my $self = shift;
    return $self->{_expect};
}



sub _log {

# $self->_log($chars)
# purpose: output Mnet::Expect session activity, as per log_expect
# $chars: logged text, non-printable characters are output as hexadecimal
# note: Mnet::Expect->spawn sets Expect log_file to use this method

    # read the current Mnet::Expect object and character string to log
    my ($self, $chars) = (shift, shift);

    # init text and hex log output lines
    #   separate hex lines are used to show non-prinatbel characters
    my ($line_txt, $line_hex) = (undef, undef);

    # note log level for expect session traffic, using log_expect
    my $log_expect = $self->{log_expect};

    # return if log_expect was set undef to disable logging
    #   this might come in handy to ensure secrets don't end up in logs
    return if not defined $log_expect;

    # loop through input hex and text characters
    foreach my $char (split(//, $chars)) {

        # append non-printable ascii characters to line_hex
        #   apply then clear _log_filter to remove passwords from line_txt
        if (ord($char) < 32) {
            $line_hex .= sprintf(" %02x", ord($char));
            if (defined $line_txt) {
                if (defined $self->{_log_filter}) {
                    if ($line_txt =~ s/\Q$self->{_log_filter}\E/****/g) {
                        $self->{_log_filter} = undef;
                    }
                }
                $self->$log_expect("log txt: $line_txt");
                $line_txt = undef;
            }

        # append printable ascii characters to line_txt, output log hex
        #   log hex always goes to debug
        } else {
            $line_txt .= $char;
            if (defined $line_hex) {
                $self->debug("log hex:$line_hex");
                $line_hex = undef;
            }
        }

    # continue looping through input characters
    }

    # output any remaining log hex and txt lines after finishing loop
    #   log hex always goes to debug, log txt controlled by log_expct value
    #   apply and clear _log_filter to remove passwords from line_txt
    $self->debug("log hex:$line_hex") if defined $line_hex;
    if (defined $line_txt) {
        if (defined $self->{_log_filter}) {
            if ($line_txt =~ s/\Q$self->{_log_filter}\E/****/g) {
                $self->{_log_filter} = undef;
            }
        }
        $self->$log_expect("log txt: $line_txt");
    }

    # finished _log method
    return;
}



sub log_expect {

=head1 log_expect

    $prior = $expect->log_expect($level)

Use this method to set a new log_expect level for expect session traffic. The
prior log_expect value will be returned.

The new log_expect level can be set to debug, info, or undefined. An undefined
log_expect disables the logging of expect session traffic, which might be
useful to keep sensitive data out of log outputs.

The default log level for expect session traffic is debug.

An invalid input log_expect level results in an error.

=cut

    # read the current Mnet::Expect object and new log level
    my ($self, $level) = (shift, shift);

    # abort with an error if input log_expect level is not valid
    croak("log_expect invalid, must be debug, info, or undef")
        if defined $level and $level !~ /^(debug|info)$/;

    # note prior log_expect value and set the new value
    my $prior_log_expect = $self->{log_expect};
    $self->{log_expect} = $level;

    # finished log_expect method, return prior_log_expct value
    return $prior_log_expect;
}



=head1 TESTING

Mnet::Expect does not include iteself include support for L<Mnet::Test>
functionality. This is a low level module that spawns expect sessions but does
not know how to talk to devices. Any desired test functionality would need to
be provided by the calling script.

=head1 SEE ALSO

L<Expect>

L<Mnet>

L<Mnet::Expect::Cli>

L<Mnet::Expect::Cli::Ios>

L<Mnet::Log>

L<Mnet::Opts::Cli>

L<Mnet::Test>

=cut

# normal package return
1;

