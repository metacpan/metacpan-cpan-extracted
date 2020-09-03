package Mnet::Test;

=head1 NAME

Mnet::Test - Record, replay, and test script inputs and outputs

=head1 SYNOPSIS

    # sample test script
    #
    #   first create an Mnet::Test file with --record <file>
    #   next replay the test with --test --replay <file>
    #   add a print statement to cause test replay to fail

    # required for this sample
    #   refer to TESTING perldoc in other Mnet modules
    use Mnet::Expect::Cli;
    use Mnet::Opts::Cli;
    use Mnet::Test;

    # other cli options could be defined and recorded in tests
    my $cli = Mnet::Opts::Cli->new;

    # the Mnet::Expect::Cli modules can record session command outputs
    my $expect = Mnet::Expect::Cli({ spawn => "ssh 1.2.3.4" });
    my $output = $expect->command("whoami");

    # stdout and stderr are captures for tests
    print "$output\n";

=head1 DESCRIPTION

Mnet::Test can be used to allow script inputs and output to be recorded to a
file, which can be replayed later to show any changes.

Other L<Mnet> modules are designed to detect and make use of Mnet::Test, if it
is being used by a script. Refer to the perldoc TESTING sections of the other
modules for explanations of how each module supports Mnet::Test usage. Also
refer to the --test, --record, and --replay options for more information.

Scripts or modules that need to save additional data to --record test data
files can call the Mnet::Test::data function to get a referenced hash key that
can be used to store data for the current script or module. The --record option
will save this data to a file at the end of script execution, and the --replay
option can be used to load that data back from the file into the
Mnet::Test::data hash.

Also note that the Mnet::Test::time function can be used to return repeatable
sequences of outputs from the perl time command during --test execution. This
helps to avoid changing timestamps causing test failures. The L<Mnet::Log>
module automatically normalizes timestamps when running tests.

Scripts that do not use L<Mnet::Opts::Cli> to parse command line options can
pass the replay file as an argument to the Mnet::Test::data function and call
the Mnet::Test::done function at the end of script execution.

Note that the optional environment variable that can be specified when creating
a new  L<Mnet::Opts::Cli> object is not parsed if the --test option is set on
the command line, since the value of this envrionment variable may change over
time, between users, systems, etc.

=head1 FUNCTIONS

Mnet::Test implements the functions listed below.

=cut

# required modules
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Mnet::Log::Conditional qw( DEBUG INFO WARN FATAL NOTICE );
use Mnet::Opts::Cli::Cache;
use Mnet::Tee;

# modules required for diff output
BEGIN { push @INC, "$1/Depends" if $INC{"Mnet/Test.pm"} =~ /(.+)Test\.pm$/; }



# init global variables and cli options used by this module
INIT {

    # init global variables
    #   Mnet::Test::data hash holds test/record/replay data, undef until used
    #   Mnet::Test::time used for test unixtime, refer to Mnet::Test::time sub
    our ($data, $time) = (undef, 0);

    # autoflush standard output
    #   so that multi-process syswrite lines are not split
    $| = 1;

    # init stdout file handle to bypass Mnet::Tee for diff output
    our $stdout = undef;
    if ($INC{"Mnet/Tee.pm"}) {
        $stdout = $Mnet::Tee::stdout;
    } else {
        open($stdout, ">&STDOUT") or die "error duping stdout, $!";
    }

    # defined --record option
    Mnet::Opts::Cli::define({
        getopt      => 'record:s',
        help_tip    => 'save test data to file for replay',
        help_text   => '
            this option works from the command line only
            files recorded can be replayed using the --replay option
            data is saved with a .new suffix, then renamed after writing
            set null to update --replay filename with new --test diff outputs
            use --test-reset option to remove opts/args from --replay files
            refer to perldoc Mnet::Test for more info
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

    # define --replay option
    Mnet::Opts::Cli::define({
        getopt      => 'replay=s',
        help_tip    => 'run with test data from record file',
        help_text   => '
            this option works from the command line only
            execute script using replay file created with --record option
            use --test-reset option to remove opts/args from --replay file
            refer to perldoc Mnet::Test for more info
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

    # define --test option
    Mnet::Opts::Cli::define({
        getopt      => 'test',
        help_tip    => 'diff output with test replay output',
        help_text   => '
            this option works from the command line only
            use to compare current script output to --replay output
            refer to perldoc Mnet::Test for more info
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

    # define --test-reset option
    Mnet::Opts::Cli::define({
        getopt      => 'test-reset:s',
        help_hide   => '1',
        help_tip    => 'reset options/args to their defaults',
        help_text   => '
            this option works from the command line only
            use --test-reset with an option name to reset option to default
            use --test-reset with no option to reset extra args to default
            use --help for individual options to check if they are recordable
            error if --test-reset is specified for non-recordable option
            refer also to norecord option in Mnet::Opts::Cli::define function
            refer to perldoc Mnet::Test for more info
        ',
    }) if $INC{"Mnet/Opts/Cli.pm"};

# finished init of options and global variables
}



sub data {

=head1 Mnet::Test::data

    \%data = Mnet::Test::data(\%opts);

This function returns a hash reference containing test/record/replay data for
the calling module or the main script. It is up to the calling module or main
script to manage its own test/record/replay data.

The opts hash ref argument is optional, and may be used if desired to specify
a replay file. Otherwise the --replay cli option will be checked if the
L<Mnet::Opts::Cli> module is used to parse command line options.

Note that care must be taken to use the hash reference returned from this
function properly. You want to save data in the returned hash reference, not
accidently create a new hash reference. For example:

    ok:     my $data = Mnet::Test::data();
            $data->{sub_hash}->{key} = $value;

    ok:     my $data = Mnet::Test::data();
            my $sub_hash = \%{$data->{sub_hash}};
            $sub_hash->{key} = $value;

    ok:     my $sub_hash = \%{Mnet::Test::data()->{sub_hash}};
            $sub_hash->{key} = $value;

    bad:    Mnet::Test::data()->{sub_hash}->{key} = $value;

    bad:    my $data = Mnet::Test::data();
            my $sub_hash = $data->{sub_hash};
            $sub_hash->{key} = $value;

Refer to the DESCRIPTION section of this document for more information on how
modules or scripts should use this function for test/record/replay data.

=cut

    # read opts hash ref arg, or set via cached cli opts
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # check for force flag, allowed from Mnet::Opts::Cli only
    my $force = shift;
    croak("invalid force option") if $force and caller ne "Mnet::Opts::Cli";

    # note the calling module name
    my $caller = caller;
    $caller = "main" if $caller eq "-e";

    # init global test data var, if not yet defined
    #   init to an empty hash ref, or from file if --replay cli opt is set
    #   force replay data reload if called with force flag from Mnet::Opts::Cli
    if (not defined $Mnet::Test::data or $force) {
        $Mnet::Test::data = {};
        _replay($opts);
    }

    # init hash ref for caller if it doesn't yet exist
    $Mnet::Test::data->{$caller} = {}
        if not exists $Mnet::Test::data->{$caller};

    # finished Mnet::Test::data function, return hash ref for calling module
    return $Mnet::Test::data->{$caller};
}



sub _diff {

# $diff = _diff(\%opts)
# purpose: returns current output and --replay diff text
# \%opts: returns undef if --test or --replay are not defined
# $diff: diff output in string format, or undef if no replay data to diff

    # read opts hash ref arg, or set via cached cli opts
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # return if test or replay options are not set
    return undef if not defined $opts->{test};
    return undef if not defined $opts->{replay};

    # abort if we can't get a copy of the current outputs
    my $outputs = Mnet::Tee::test_outputs();
    FATAL("undefined current test data") if not defined $outputs;

    # abort if there's no replay test data outputs
    my $test_data = data($opts);
    FATAL("undefined --replay test data")
        if not defined $test_data->{outputs};

    # init diff output, use Text::Diffs if available
    my $diff = "";
    if ($outputs ne $test_data->{outputs}) {
        eval("require Text::Diff; 1");
        $diff = "Test output is different, need Text::Diff to show more.\n";
        $diff = Text::Diff::diff(\$test_data->{outputs}, \$outputs)
            if $INC{"Text/Diff.pm"};
    }

    # output detected differences, unless running in --batch mode
    #   Mnet::Test::test_pause used to keep test diff output out of test data
    if (not $opts->{batch}) {
        my $was_paused = Mnet::Tee::test_paused();
        Mnet::Tee::test_pause();
        syswrite $Mnet::Test::stdout, "\n" . "-" x 79 . "\n";
        syswrite $Mnet::Test::stdout, "diff --test --replay $opts->{replay}";
        syswrite $Mnet::Test::stdout, "\n" . "-" x 79 . "\n\n";
        if ($diff) {
            syswrite $Mnet::Test::stdout, $diff;
        } else {
            syswrite $Mnet::Test::stdout, "Test output is identical.\n";
        }
        syswrite $Mnet::Test::stdout, "\n";
        Mnet::Tee::test_unpause() if not $was_paused;
    }

    # finished _diff function
    return $diff;
}



sub done {

=head2 Mnet::Test::done

    $diff = Mnet::Test::done(\%opts)

This function does one or two things, depending on the how the record, replay,
and test options are set.

If the --replay and --test options are set a diff of test output will be
returned, or a value of undefined if there was no replay data.

If the --record option is set then the Mnet::Test data captured from the
current script execution will be saved to the specified file.

This function is called automatically at script exit using the --record,
--replay, and --test options parsed from a prior Mnet::Opts::Cli->new
call. You do not need to call this function unless you are not using
L<Mnet::Opts::Cli> to parse command line options or if you want to examine
your own test diff data.

If the test output has changed a diff will be presented using the L<Text::Diff>
module.

Refer to the DESCRIPTION section of this document for more information.

=cut

    # read opts hash ref arg, or set via cached cli opts
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # diff replay output if replay and test options are set true
    my $diff = _diff($opts);

    # record to file, if ncessary
    #   record if set to a specified file
    #   record if there's a test diff
    if (defined $opts->{record}) {
        if ($opts->{record} ne "") {
            _record($opts);
        } elsif ($diff) {
            _record($opts);
        }
    }

    # output warning for test diff in --batch mode
    #   batch child output gets silent pragma set by parent
    #   this will cause children to throw an error if they have a test diff
    #   batch parent will output a warning when it reaps child with an error
    FATAL("batch mode test output is different") if $opts->{batch} and $diff;

    # finished done function, return diff output
    return $diff;
}



sub _record {

# _record(\%opts)
# purpose: dump test data to a file, returns if record option is undef
# \%opts: looks for record hash ref key, uses replay filename if set null

    # read opts hash ref arg, or set via cached cli opts
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # return if --record option is not set
    return if not defined $opts->{record};

    # add current captured input to data before recording to file
    $Mnet::Test::data->{"Mnet::Test"}->{outputs} = Mnet::Tee::test_outputs();

    # prepare to dump test data
    my $dumper = Data::Dumper->new([$Mnet::Test::data]);
    $dumper->Sortkeys(1);
    my $dump = $dumper->Dump;

    # replace default Data::Dumper var name with something more descriptive
    #   this will help discourage bypassing this module to access these files
    $dump =~ s/^\$VAR1/\$Mnet::Test::data/g;

    # log dump of test data that we are going to save
    if ($opts->{debug}) {
        DEBUG("_record: $_") foreach split(/\n/, $dump);
    }

    # update --replay file if --record is set null
    my $record_file = $opts->{record};
    $record_file = $opts->{replay} if $record_file eq "";
    FATAL("null --record set without --replay file")
        if not defined $record_file or $record_file eq "";

    # read dump of test data from replay file, abort on errors
    open(my $fh, ">", $record_file)
        or FATAL("error opening --record $record_file, $!");
    print $fh $dump;
    close $fh;

    # finished _record function
    return;
}



sub _replay {

# _replay(\%opts)
# purpose: read Mnet::Test::data global hash ref data from replay file
# \%opts: hash ref w/replay file, or undef to use Mnet::Opts::Cli::Cache
# note: this is called from Mnet::Test::data()

    # read opts hash ref arg, or set via cached cli opts
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # return if replay option is not set
    return if not defined $opts->{replay};

    # create log object using current options
    my $log = Mnet::Log::Conditional->new($opts);

    # read dump of test data from replay file, abort on errors
    my $dump = "";
    open(my $fh, "<", $opts->{replay})
        or $log->fatal("error opening --replay $opts->{replay}, $!");
    $dump .= $_ while <$fh>;
    close $fh;

    # log dump of test data that we just read
    if ($opts->{debug}) {
        $log->debug("replay: $_") foreach split(/\n/, $dump);
    }

    # restore variable name before eval of Data::Dumper file data
    $dump =~ s/^\$Mnet::Test::data/\$data/;

    # eval replay dump data, warn on eval syntax problems
    my $data = undef;
    eval {
        local $SIG{__WARN__} = sub { $log->warn("@_") };
        $data = eval $dump;
    };
    $Mnet::Test::data = $data;

    # abort if replay test data hash ref eval failed
    $log->fatal("replay eval failed for --replay $opts->{replay}")
        if ref $Mnet::Test::data ne "HASH";

    # finished replay function
    return;
}



sub time {

=head2 Mnet::Test::time

    $unixtime = Mnet::Test::time($incrememt)
    or $unixtime = Mnet::Test::time(\%opts, $increment)

This function can be used by project scripts to get repeatable unixtime output
during executions with the --test, --record, or --replay cli options set, and
real time from the perl time command otherwise.

An optional incrememnt value can be specified in seconds, and defauls to the
returned time being incremented by one second for each call to this function.

This function can be called with an opts hash ref, which can have record and
replay keys set to indicate test output is needed. Otherwise these options are
expected to be set via the L<Mnet::Opts::Cli> module.

=cut

    # read input args, increment might be only arg, opts defaults to cached cli
    my ($opts, $increment) = (shift, shift);
    ($increment, $opts) = ($opts, Mnet::Opts::Cli::Cache::get({}))
        if not ref $opts;

    # default to a one second increment for each call
    $increment = 1 if not $increment;

    # init output unixtime to real time
    my $unixtime = time;

    # set output incremented test time if test/record/replay options are set
    if (defined $opts->{record} or $opts->{replay} or $opts->{test}) {
        $unixtime = $Mnet::Test::time += $increment;
    }

    # finished Mnet::Test::time function, return unixtime
    return $unixtime;
}



# process --record and --test cli options, unless Mnet::Log is loaded
#   called from Mnet::Log end block if loaded, after last log line output
#   --test diff undef if --replay --test diff was not attempted
#   --test diff is null for no diff, exit clean even if output had errors
#   --test diff is non-null for failed diff, exit with a failed status
END {
    if (not $INC{"Mnet/Log.pm"}) {
        my $diff = Mnet::Test::done();
        exit 0 if defined $diff;
        exit 1 if $diff;
    }
}



=head1 SEE ALSO

L<Mnet>

L<Mnet::Expect::Cli>

L<Mnet::Log>

L<Mnet::Opts::Cli>

L<Mnet::Report::Table>

L<Text::Diff>

=cut

# normal end of package
1;

