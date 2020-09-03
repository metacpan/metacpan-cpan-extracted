package Mnet::Log;

=head1 NAME

Mnet::Log - Logging, compatible with Log4perl

=head1 SYNOPSIS

    # imports DEBUG, INFO, WARN, and FATAL
    use Mnet::Log qw( DEBUG INFO WARN FATAL );

    # options can be set for Mnet::Log objects
    my $log = Mnet::Log->new();

    # output to standard out and err is captured
    syswrite STDOUT, $text;
    syswrite STDERR, $text;

    # dbg entries
    DEBUG($text);
    $log->debug($text);

    # inf entries
    INFO($text);
    $log->info($text);

    # WRN entries
    WARN($text);
    $log->warn($text);

    # ERR entries
    #  note that eval warnings are output as normal
    #  evals can use local $SIG{__WARN__} = sub { die @_ };
    warn $text;
    die $text;

    # DIE entries
    FATAL($text);
    $log->fatal($text);

    # first line of first WRN/ERR/DIE entry
    $text = Mnet::Log::error();

=head1 DESCRIPTION

Mnet::Log supports generating the following types of log entries

    dbg   stdout   detailed info, visible when debug option is set
    inf   stdout   normal informational entries intended for users
    ---   stdout   reserved for Mnet notices, ignored by --test
    WRN   stderr   logged warning entries, execution continues
    ERR   stderr   perl die and warn outputs with stack trace
    DIE   stderr   logged fatal errors, execution aborts

The following options can be used to control log outputs:

    debug   enable dbg log outputs
    quiet   disable all stdout log outputs
    silent  disable all stdout and stderr log outputs

Note that this module also installs __DIE__, __WARN__, INT, and TERM signal
handlers, in order to augment the logging of these events. These are made so
that compile and eval signals are processed by perl as normal.

Note that timestamps and other varying data are filtered out of log outputs
when the --record, --replay, or --test cli options are enabled or if the
L<Mnet::Log::Test> module is otherwise loaded.

=head1 METHODS

Mnet::Log implements the methods listed below.

=cut

# required modules
#   perl 5.8 required for decent signal handling, refer to man perlipc
#   note that Mnet modules should use Mnet::Log::Conditional, not this module
use warnings;
use strict;
use 5.008;
use Carp;
use Exporter qw( import );
use Mnet::Opts;
use Mnet::Opts::Cli::Cache;
use Mnet::Version;
use Time::HiRes;

# export function names
our @EXPORT_OK = qw( DEBUG INFO WARN FATAL );

# begin block runs before init blocks of other modules
BEGIN {

    # autoflush standard output
    #   so that multi-process syswrite lines are not split
    $| = 1;

    # note start time of script, seconds since epoch, floating point
    our $start_time = Time::HiRes::time();

    # init global flag to track that first log message was output
    #   this is used to output log entry when script started and finished
    my $first = undef;

    # init global error flag, user to track first error message
    #   should be set for perl warn and die, and warn and fatal Mnet::Log calls
    my $error = undef;

    # init global variable used to accumulate --debug-error output
    #   starts off as null, undef disables, refer to disable_debug_error sub
    our $debug_error = "";

    # declare sub used by SIG handlers to log error and stack trace info
    sub _sig_handler {
        my ($label, $caller, $error, $sev) = (shift, shift, shift, 7);
        $sev = 3 if not defined $Mnet::Log::error;
        output(undef, "ERR", 3, $caller, "$label, $error");
        output(undef, "err", $sev, $caller, "$label, $_")
            foreach split(/\n/, Carp::longmess());
        output(undef, "err", $sev, $caller, "$label, \$! = $!") if $! ne "";
        output(undef, "err", $sev, $caller, "$label, \$@ = $@") if $@ ne "";
        output(undef, "err", $sev, $caller, "$label, \$? = $?") if $? ne "";
        output(undef, "err", $sev, $caller, "$label, \$^E = $^E") if $^E ne "";
    }

    # trap perl die signal, log as error and exit with a failed status
    #   CORE::die handles propogated, compile, and eval warnings
    #   $^S is undef while compiling/parsing, true in eval, false otherwise
    #   exit with error after _sig_handler call to output error and stack trace
    $SIG{__DIE__} = sub {
        if (not @_ or not defined $^S or $^S) {
            CORE::die(@_);
        } else {
            _sig_handler("perl die", scalar(caller), "@_");
        }
        exit 1;
    };

    # trap perl warn signal, log as error and resume execution
    #   CORE::warn handles propogated and compile warnings
    #   $^S is undef while compiling/parsing, true in eval, false otherwise
    #   return after _sig_handler call to output error and stack trace
    $SIG{__WARN__} = sub {
        if (not @_ or not defined $^S) {
            CORE::warn(@_);
        } else {
            _sig_handler("perl warn", scalar(caller), "@_");
        }
        return 1;
    };

    # trap system interrupt signal, log as error and exit with failed status
    #   output a linefeed to stderr after ^C put there by shell
    $SIG{INT} = sub {
        syswrite STDERR, "\n";
        output(undef, "ERR", 3, scalar(caller), "terminate signal received");
        exit 1;
    };

    # trap terminate signal, log as error and exit with failed status
    $SIG{TERM} = sub {
        output(undef, "ERR", 3, scalar(caller), "terminate signal received");
        exit 1;
    };

# begin block finished
}



# init cli options used by this module
INIT {

    # init --debug option
    Mnet::Opts::Cli::define({
        getopt      => 'debug!',
        help_tip    => 'set to display extra debug log entries',
        help_text   => '
            note that the --quiet and --silent options override this option
            refer also to the Mnet::Opts::Set::Debug pragma module
            refer to perldoc Mnet::Log for more information
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

    # init --debug-error option
    Mnet::Opts::Cli::define({
        getopt      => 'debug-error=s',
        help_hide   => 1,
        help_tip    => 'set for debug file on errors, or stdout',
        help_text   => '
            set to the path and name of debug file to write after any errors
            this way you get debug logs for errors, and normal logs otherwise
            any asterisk in filename will be replaced with timestamp and pid
            send output to terminal using --debug-error /dev/stdout or stderr
            refer to perldoc Mnet::Log for more information
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

    # init --quiet option
    Mnet::Opts::Cli::define({
        getopt      => 'quiet!',
        help_tip    => 'suppresses terminal stdout logging',
        help_text   => '
            suppresses Mnet::Log stdout entries, not necessarily other stdout
            use shell redirection if necessary to suppress all script stdout
            note that setting this option overrides the --silent option
            refer also to the Mnet::Opts::Set::Quiet pragma module
            refer to perldoc Mnet::Log for more information
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

    # init --silent option
    Mnet::Opts::Cli::define({
        getopt      => 'silent!',
        help_tip    => 'suppresses stdout and stderr logging',
        help_text   => '
            suppresses all Mnet::Log output, but not necessarily other output
            use shell redirection if necessary to suppress all script output
            note that this option can be overridden by the --quiet option
            refer also to the Mnet::Opts::Set::Silent pragma module
            refer to perldoc Mnet::Log for more information
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

# finished init code block
}



sub new {

=head2 new

    $log = Mnet::Log->new(\%opts)

This class method creates a new Mnet::Log object. The opts hash ref
argument is not requried but may be used to override any parsed cli options
parsed with the L<Mnet::Opts::Cli> module.

The returned object may be used to call other documented methods in this module.

The input opts hash ref may contain a log_id key which may be set to a device
name or other identifier which will be prepended to all entries made using the
returned Mnet::Log object. A warning will be issued if the log_id contains any
spaces.

Refer to the SYNOPSIS section of this perldoc for more information.

=cut

    # read input class and options hash ref merged with cli options
    my $class = shift // croak("missing class arg");
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # croak if log_id contains non-space characters
    croak("invalid spaces in log_id $opts->{log_id}")
        if defined $opts->{log_id} and $opts->{log_id} !~ /^\S+$/;

    # create log object from options object
    my $self = bless $opts, $class;

    # finished new method
    return $self;
}



sub batch_fork {

# Mnet::Log::batch_fork($error_reset)
# purpose: called to reset start time for forked batch child
# $error_reset: used to reset Mnet::Log::error before child executes
# note: this is meant to be called from Mnet::Batch::fork only

    # reset forked child error, start time, debug error, and first log entry
    my $error_reset = shift;
    $Mnet::Log::error = $error_reset;
    $Mnet::Log::start_time = Time::HiRes::time();
    $Mnet::Log::debug_error = "";
    $Mnet::Log::first = 0;
}



sub disable_debug_error {

# Mnet::Log::disable_debug_error()
# purpose: called from Mnet::Opts::Cli if --debug_error not on command line

    # set global debug_error to undef to disable, to save memory
    $Mnet::Log::debug_error = undef;
}


sub error {

=head2 Mnet::Log::error

    $error = Mnet::Log::error();

This function returns the first line of error text from the perl warn or die
commands or Mnet::Log warn or fatal outputs.

A value of undefined is returned if there have not yet been any errors.

=cut

    # return contents of global error flag
    return $Mnet::Log::error;
}



sub output {

# $true = output($self, $prefix, $severity, $caller, $text)
# purpose: used by other methods in this module to output Mnet::Log entries
# $self: object instance passed from public methods in this module, or undef
# $prefix: set to keyword dbg, inf, WRN, ERR, or "---" to bypass Mnet::Tee
# $severity: 7=debug, 6=info, 5=notice (no Mnet::Test), 4=warn, 3=error, 2=fatal
# $caller: original caller of method or function making log entry
# $text: zero or more lines of log text, timestamp/caller/etc will be added
# $true: boolean true is always returned, can use like: output() and ...

    # read args for object and/or text, level, and caller
    my ($self, $prefix, $severity, $caller) = (shift, shift, shift, shift);
    my $text = shift // "undef log text";
    $text = " " if $text eq "";

    # set self to hash ref of cached cli opts if we weren't called as a method
    $self = Mnet::Opts::Cli::Cache::get({}) if not defined $self;

    # output first log entry, honoring current logging options
    #   Mnet::Opts::Set pragmas are in effect until Mnet::Opts::Cli->new call
    #   project scripts should call Mnet::Opts::Cli->new before Mnet::Log calls
    #   notice call for first line bypasses saving in Mnet::Tee::test_outputs
    #   filter pid if Mnet::Log::Test loaded, perhaps by Mnet::Opts::Cli->new
    if (not $Mnet::Log::first) {
        $Mnet::Log::first = 1;
        my $script_name = $0;
        $script_name =~ s/^.*\///;
        my $started = "$script_name started";
        if (not $INC{"Mnet/Log/Test.pm"}) {
            $started .= ", pid $$, ".localtime($Mnet::Log::start_time);
        }
        $Mnet::Log::debug_error = undef if not $INC{"Mnet/Opts/Cli.pm"};
        NOTICE($started);
        output(undef, "dbg", 7, "Mnet::Version", Mnet::Version::info());
    }

    # return early for debug entries if no --debug set and debug_error disabled
    return 1 if $severity > 6
       and not $self->{debug}
       and not defined $Mnet::Log::debug_error;

    # update global error flag with first line of first error entry
    $Mnet::Log::error = "$caller ".(split(/\n/, $text))[0]
        if $severity < 5 and not defined $Mnet::Log::error;

    # set hh:mm:ss timestamp for entries as long as --test is not set
    #   timestamps are filtered from output with --test/record/replay cli opts
    my ($timestamp, $sec, $min, $hr, $mday, $mon, $yr) = ("", localtime());
    $timestamp = sprintf("%02d:%02d:%02d ", $hr, $min, $sec)
        if not $INC{"Mnet/Log/Test.pm"} and not $self->{test}
        and not $self->{record} and not $self->{replay};

    # note identifier for Mnet::Log entries
    my $log_id  = $self->{log_id} // "-";

    # loop through lines of text and output log entries
    foreach my $line (split(/\n/, $text)) {

        # prepare output log entry for each line of text
        $line = "${timestamp}$prefix $log_id $caller $line";

        # accumulate all output log entries to --debug-error buffer
        $Mnet::Log::debug_error .= "$line\n" if defined $Mnet::Log::debug_error;

        # stdout sev 7 debug
        #   not included in Mnet::Tee::test_outputs
        #   if --quiet or --silent set then output to --tee file only
        if ($severity == 7 and $self->{debug}) {
            Mnet::Tee::test_pause() if $INC{"Mnet/Tee.pm"};
            if ($self->{silent} or $self->{quiet}) {
                Mnet::Tee::tee_no_term("$line\n") if $INC{"Mnet/Tee.pm"};
            } else {
                syswrite STDOUT, "$line\n";
            }
            Mnet::Tee::test_unpause() if $INC{"Mnet/Tee.pm"};

        # stdout sev 6 info
        #   included in Mnet::Tee::test_outputs
        #   if --quiet or --silent set then output to --tee file only
        } elsif ($severity == 6) {
            if ($self->{silent} or $self->{quiet}) {
                Mnet::Tee::tee_no_term("$line\n") if $INC{"Mnet/Tee.pm"};
            } else {
                syswrite STDOUT, "$line\n";
            }

        # stdout sev 5 notice
        #   not included in Mnet::Tee::test_outputs
        #   if --quiet or --silent set then output to --tee file only
        } elsif ($severity == 5) {
            Mnet::Tee::test_pause() if $INC{"Mnet/Tee.pm"};
            if ($self->{silent} or $self->{quiet}) {
                Mnet::Tee::tee_no_term("$line\n") if $INC{"Mnet/Tee.pm"};
            } else {
                syswrite STDOUT, "$line\n";
            }
            Mnet::Tee::test_unpause() if $INC{"Mnet/Tee.pm"};

        # stderr sev 4 warn, sev 3 error, and sev 2 fatal
        #   included in Mnet::Tee::test_outputs
        #   if --silent set then output to --tee file only
        } elsif ($severity < 5) {
            if ($self->{silent} and not $self->{quiet}) {
                Mnet::Tee::tee_no_term("$line\n") if $INC{"Mnet/Tee.pm"};
            } else {
                syswrite STDERR, "$line\n";
            }
        }

    # continue looping through lines of text
    }

    # finished output function
    return 1;
}



sub debug {

=head2 debug

    $log->debug($text)

Output a debug entry to stdout with an Mnet::Log prefix of dbg.

=cut

    # call output function
    my ($self, $text) = (shift, shift);
    return $self->output("dbg", 7, scalar(caller), $text);
}



sub info {

=head2 info

    $log->info($text)

Output an info entry to stdout with an Mnet::Log prefix of inf.

=cut

    # call output function
    my ($self, $text) = (shift, shift);
    return $self->output("inf", 6, scalar(caller), $text);
}



sub notice {

# $self->notice($text)
# purpose: output log text to stdout, bypassing Mnet::Test log capture
# $text: zero or more lines of log text, timestamp/caller/etc will be added

    # call output function
    my ($self, $text) = (shift, shift);
    return output($self, "---", 5, scalar(caller), $text);
}



sub warn {

=head2 warn

    $log->warn($text)

Output a warn entry to stderr with an Mnet::Log prefix of WRN.

=cut

    # call output function
    my ($self, $text) = (shift, shift);
    return $self->output("WRN", 4, scalar(caller), $text);
}



sub fatal {

=head2 fatal

    $log->fatal($text)

Output a fatal entry to stderr with an Mnet::log prefix of DIE. Note that calls
to fatal are handled in an eval the same as calls to die.

=cut

    # call normal die in an eval, otherwise call output function
    #   $^S is undef while compiling/parsing, true in eval, false otherwise
    my ($self, $text) = (shift, shift);
    CORE::die("$text\n") if $^S;
    $self->output("DIE", 2, scalar(caller), $text);
    exit 1;
}



=head1 FUNCTIONS

Mnet::Log also implements the functions listed below.

=cut



sub DEBUG {

=head2 DEBUG

    DEBUG($text)

Output a debug entry to stdout with an Mnet::Log prefix of dbg.

=cut

    # call output function
    my $text = shift;
    return output(undef, "dbg", 7, scalar(caller), $text);
}



sub INFO {

=head2 INFO

    INFO($text)

Output an info entry to stdout with an Mnet::Log prefix of inf.

=cut

    # call output function
    my $text = shift;
    return output(undef, "inf", 6, scalar(caller), $text);
}



sub NOTICE {

# NOTICE($text)
# purpose: output log text to stdout, bypassing Mnet::Test log capture
# $text: zero or more lines of log text, timestamp/caller/etc will be added

    # call output function
    my $text = shift;
    return output(undef, "---", 5, scalar(caller), $text);
}



sub WARN {

=head2 WARN

    WARN($text)

Output a warn entry to stderr with an Mnet::Log prefix of WRN.

=cut

    # call output function
    my $text = shift;
    return output(undef, "WRN", 4, scalar(caller), $text);
}



sub FATAL {

=head2 FATAL

    FATAL($text)

Output a fatal entry to stderr with an Mnet::Log prefix of DIE. Note that calls
to fatal are handled in an eval the same as calls to die.

=cut

    # call normal die in an eval, otherwise call output function
    #   $^S is undef while compiling/parsing, true in eval, false otherwise
    my $text = shift;
    CORE::die("$text\n") if ($^S);
    output(undef, "DIE", 2, scalar(caller), $text);
    exit 1;
}



# output Mnet::Log finished entry at end of script
#   output log prefix "---" bypasses Mnet::Test recording of these entries
END {

    # note --debug_error filename, substitute unique timestamp/pid for asterisk
    #   unique timestampt/pid allows for --debug_error used from batch parent
    my $debug_error_file = Mnet::Opts::Cli::Cache::debug_error();
    if (defined $debug_error_file) {
        my ($sec, $min, $hr, $mday, $mon, $yr) = localtime();
        $yr += 1900; $mday += 1;
        my $date_stamp = sprintf("%02s-%02s-%02s", $yr, $mon, $mday);
        my $time_stamp = sprintf("%02s:%02s:%02s", $hr, $min, $sec);
        $debug_error_file =~ s/\*/${date_stamp}_${time_stamp}_pid-$$/;
    }

    # prepare summary/finished info for last log entry
    my $finished = "no errors";
    $finished = "exit error status" if $?;
    $finished = "errors" if defined $Mnet::Log::error;
    my $elapsed = Time::HiRes::time - $Mnet::Log::start_time;
    $elapsed = sprintf("%.3f secs elapsed", $elapsed);
    $finished .= ", pid $$, $elapsed" if not $INC{"Mnet/Log/Test.pm"};

    # output notice of errors
    #   only if Mnet::Log::error is set, will be text of first error
    #   only if first line was output, meaning logging was enabled/used
    #   only if Mnet::Log::Test was not used to filter varying log outputs
    #   Mnet::Opts::Cli->new loads Mnet::Log::Test if --test/record/replay set
    NOTICE("detected at least one error, $Mnet::Log::error")
        if defined $Mnet::Log::error
        and $Mnet::Log::first
        and not $INC{"Mnet/Log/Test.pm"};

    # output notice if we will be writing --debug-error output
    #   this puts notice on screen, in file, and before finished message
    NOTICE("creating --debug-error $debug_error_file")
        if $Mnet::Log::error and defined $debug_error_file;

    # output last finished log notice
    #   only if first line was output, meaning logging was enabled/used
    NOTICE("finished, $finished") if $Mnet::Log::first;

    # output --debug-error file, if there were errors and that opt was set
    if (defined $Mnet::Log::error and defined $debug_error_file) {
        if (open(my $fh, ">", $debug_error_file)) {
            my ($sep1, $sep2) = ("-" x 14, "-" x 36);
            syswrite $fh, "\n$sep1 DEBUG ERROR OUTPUT STARTING $sep2\n\n";
            syswrite $fh, $Mnet::Log::debug_error // "<undef>\n";
            syswrite $fh, "\n$sep1 DEBUG ERROR OUTPUT FINISHED $sep2\n\n";
            close $fh;
        } else {
            WARN("unable to open --debug_error $debug_error_file, $!");
        }
    }

    # call Mnet::Test to process --record and --test cli opt, if loaded
    #   called here so that tests occur after last line of Mnet::Log output
    #   --test diff undef if --replay --test diff was not attempted
    #   --test diff is null for no diff, exit clean even if output had warnings
    #   --test diff is non-null for failed diff, exit with a failed status
    if ($INC{"Mnet/Test.pm"}) {
        my $diff = Mnet::Test::done();
        if (defined $diff) {
            exit 0 if not $diff;
            exit 1 if $diff;
        }
    }

    # set failed exit status if any errors were caught by signal handlers
    exit 1 if defined $Mnet::Log::error;

# finished end block
}



=head1 TESTING

When used with the L<Mnet::Test> --record option all stdout and stderr log
entry output from this module is captured with the exception of dbg entries.

Refer to the L<Mnet::Test> module for more information.

=head1 SEE ALSO

L<Mnet>

L<Mnet::Log::Conditional>

L<Mnet::Log::Test>

L<Mnet::Opts::Cli>

L<Mnet::Opts::Set::Debug>

L<Mnet::Opts::Set::Quiet>

L<Mnet::Opts::Set::Silent>

L<Mnet::Test>

L<Mnet::Version>

=cut

# normal end of package
1;

