package Spreadsheet::Compare 0.13;

# TODO: (issue) allow list for reporters

use Mojo::Base 'Mojo::EventEmitter', -signatures;
use Module::Load qw(autoload load);
use Mojo::IOLoop;
use Config;

use Spreadsheet::Compare::Common;
use Spreadsheet::Compare::Config {}, protected => 1;
use Spreadsheet::Compare::Single;

my( $trace, $debug );

my @counter_names = Spreadsheet::Compare::Single->counter_names;

#<<<
has _cfo      => undef;
has config    => undef;
has errors    => sub { [] }, ro => 1;
has exit_code => 0;
has jobs      => 1;
has log_level => sub { $ENV{SPREADSHEET_COMPARE_DEBUG} };
has quiet     => undef;
has result    => sub { {} }, ro => 1;
has stdout    => undef;
#>>>

# emitted by Spreadsheet::Compare::Single
has _reporter_events => sub { [ qw(
    _after_reader_setup
    add_stream
    mark_header
    write_fmt_row
    write_header
    write_row
) ] };

# emitted by Spreadsheet::Compare::Single
has _test_events => sub { [ qw(
    after_fetch
    counters
    final_counters
) ] };


sub _setup_readers ( $self, $test ) {

    my $modname = "Spreadsheet::Compare::Reader::$test->{type}";
    INFO "loading $modname";
    load($modname);

    my %args = map { $_ => $test->{$_} } grep { $modname->can($_) } keys %$test;

    my @readers;
    for my $index ( 0, 1 ) {
        $debug and DEBUG "creating $modname instance $index";
        my $reader = $modname->new(
            %args,
        ) or LOGDIE "could not create $modname object";

        $reader->{__ro__index} = $index;

        my $side_name = $index ? $test->{right} : $test->{left};
        $reader->{__ro__side_name} = $side_name if $side_name;

        push @readers, $reader;
    }

    $test->{readers} = \@readers;

    return $self;
}


sub _setup_reporter ( $self, $test, $single ) {

    if ( not $test->{reporter} or $test->{reporter} =~ /^none$/i ) {
        $self->{_current_reporter} = undef;
        return;
    }

    my $modname = "Spreadsheet::Compare::Reporter::$test->{reporter}";
    $debug and DEBUG "creating $modname instance";
    load($modname);

    my %args = map { $_ => $test->{$_} } grep { $modname->can($_) } keys %$test;

    $args{report_filename} =~ s/\s+/_/g if $args{report_filename};

    INFO "Reporter Args: ", Dump( \%args );
    $self->{_current_reporter} = my $rep_obj = $modname->new( \%args );
    $rep_obj->{__ro__test_title} = $test->{title};
    $rep_obj->setup();
    for my $ev ( $self->_reporter_events->@* ) {
        $trace and TRACE "subscribe event $ev";
        $single->on(
            $ev,
            sub ( $em, @args ) {
                $trace and TRACE "calling $ev for reporter $test->{reporter}";
                $rep_obj->$ev(@args);
            }
        );
    }

    return $self;
}


sub init ($self) {
    die "jobs has to be an integer > 0\n" if $self->jobs < 1;

    unless ( $Config{d_fork} or $Config{d_pseudofork} ) {
        warn "cannot use fork, resetting jobs to 1\n";
        $self->jobs(1);
    }

    $self->_setup_logging();
    ( $trace, $debug ) = get_log_settings();

    $self->_cfo( Spreadsheet::Compare::Config->new( from => $self->config ) );

    return $self;
}


sub run ($self) {

    local $| = 1 if $self->stdout;

    unless ($self->_cfo->plan->@*) {
        croak "no configuration given!" unless $self->config;
        $self->_cfo->load($self->config);
    }
    my $cfg = $self->_cfo;

    my %summary;
    my $result = $self->result;
    my @sp_queue;
    $self->errors->@* = ();

    $self->on(
        summary => sub ( $s, $sdata ) {
            INFO "Adding result to $sdata->{type} summary info";
            my $suite_sum = $summary{ $sdata->{type} }{ $sdata->{suite_title} } //= [];
            push @$suite_sum, $sdata;
        }
    );

    my $no_counters = $self->quiet || $ENV{HARNESS_ACTIVE};
    if ( $self->stdout and not $no_counters ) {
        $self->on( counters => sub ( $s, @data ) { $self->_output_line_counter(@data) } );
    }

    $self->on(
        final_counters => sub ( $s, @data ) {
            my( $title, $counter ) = @data;
            $result->{$title} = $counter;
        }
    );

    $self->_mod_check($cfg);

    while ( my $test = $cfg->next_test ) {

        if ( $self->jobs == 1 ) {    # run instantly
            try { $self->_single_run($test) } catch { $self->_handle_error( $test, $_ ) };
        }
        else {                       # queue for running in subprocess
            push(
                @sp_queue, {
                    test => $test,
                    sub  => sub ($sp) { $self->_single_run( $test, $sp ) },
                }
            );
        }

    }

    $self->_run_subprocesses( \@sp_queue ) if @sp_queue;

    if ( $self->stdout ) {
        say "" unless $self->quiet;
        for my $title ( sort keys %$result ) {
            say $title;
            my $cnt   = $result->{$title};
            my $cline = sprintf "LEF:%06s RIG:%06s SAM:%06s DIF:%06s LIM:%06s MIS:%06s ADD:%06s DUP:%06s",
                @$cnt{@counter_names};
            say $cline;
        }
    }

    my $globals = $cfg->globals;
    for my $stype ( keys %summary ) {
        INFO "Writing $stype summary file";
        my $modname = "Spreadsheet::Compare::Reporter::$stype";
        load($modname);
        my $reporter = $modname->new( rootdir => $globals->{rootdir} // '.' );
        $reporter->write_summary( $summary{$stype}, $globals->{summary_filename} // $globals->{title} );
    }

    my $ec = $self->{failed} // 0;
    $ec = 255 if $ec > 255;
    $self->exit_code($ec);

    return $self;
}


sub _mod_check ( $self, $cfg ) {

    if ( $self->jobs > 1 and $^O eq 'MSWin32' ) {
        try {
            load('Mojo::IOLoop::Thread');
            my $ver = $Mojo::IOLoop::Thread::VERSION;
            croak "$ver" if $ver < 0.10;
        }
        catch {
            warn "--jobs with a value > 1 needs Mojo::IOLoop::Thread >= 0.10 , resetting to 1!\n";
            $self->jobs(1);
        };
    }

    my $has_csv = any { $_->{type} eq 'CSV' } $cfg->plan->@*;
    if ( $self->jobs > 1 and $^O eq 'MSWin32' and $has_csv ) {
        warn "--jobs with a value > 1 uses Text::CSV_PP, which may be slower than\n";
        warn "using the default (--jobs 1) and being able to use the non thread safe\n";
        warn "Text::CSV_XS.\n";
        $ENV{PERL_TEXT_CSV} = 'Text::CSV_PP';
    }

    return $self;
}


sub _run_subprocesses ( $self, $queue ) {
    my $max    = $self->jobs;
    my $ioloop = Mojo::IOLoop->singleton;

    my $todo    = @$queue;
    my $started = my $finished = 0;
    $ioloop->recurring(
        0.1 => sub ($loop) {
            if ( $started - $finished < $max ) {
                my $sproc = Mojo::IOLoop->subprocess;
                $sproc->on( progress => sub ( $sp, @data ) { $self->emit(@data) } );
                if ( my $job = shift @$queue ) {
                    $sproc->run(
                        $job->{sub},
                        sub ( $sp, $err, @results ) {
                            $finished++;
                            return unless $err;
                            $self->_handle_error( $job->{test}, $err );
                        },
                    );
                    $started++;
                }
            }
            $loop->stop if $finished == $todo;
        },
    );
    $ioloop->start;

    return $self;
}


sub _single_run ( $self, $test, $sp = undef ) {
    $self->_setup_logging($test);

    $self->{new_test} = 1;

    INFO '';
    INFO '=' x 50;
    INFO "|| RUNNING TEST >>$test->{title}<<";
    INFO '=' x 50;

    $debug and DEBUG 'running compare with config:', sub { Dump($test) };
    $self->_setup_readers($test);

    my $single = Spreadsheet::Compare::Single->new($test);

    my $title = join( '/', $test->{suite_title}, $test->{title} );
    INFO "running comparison $title";

    $self->_setup_reporter( $test, $single );

    my $emit =
          $sp
        ? $^O eq 'MSWin32'
            ? \&Mojo::IOLoop::Thread::progress
            : \&Mojo::IOLoop::Subprocess::progress
        : \&Mojo::EventEmitter::emit;
    $sp //= $self;

    for my $ev ( $self->_test_events->@* ) {
        $single->on( $ev => sub ( $e, @data ) { $sp->$emit( $ev, $title, @data ) } );
    }

    my $result = $single->compare();

    if ( my $reporter = $self->{_current_reporter} ) {
        $sp->$emit( 'report_finished', $title, ref($reporter), $reporter->report_fullname->stringify );
        $reporter->save_and_close;
        if ( my $stype = $test->{summary} ) {
            ( my $ttitle = $test->{title} )       =~ s/[^\w]/_/g;
            ( my $stitle = $test->{suite_title} ) =~ s/[^\w]/_/g;
            $sp->$emit(
                'summary', {
                    type        => $stype,
                    full        => "${ttitle}_$stitle",
                    title       => $ttitle,
                    suite_title => $test->{suite_title},
                    result      => {%$result},             # in case the reporter changes the hash
                    report => $reporter ? path( $reporter->report_fullname )->absolute : '',
                }
            );
        }
    }

    return $self;
}


sub _handle_error ( $self, $test, $err ) {
    my $msg = "failed to run compare for '$test->{title}', $err";
    say $msg if $self->stdout;
    ERROR $msg;
    ERROR call_stack() if $debug;
    push $self->errors()->@*, $msg;
    $self->{failed}++;
    return;
}


sub _output_line_counter ( $self, $title, $counters ) {
    state $all = {};
    my $first = !scalar( keys %$all );
    $all->{$title} = $counters;
    my $cstr = sprintf( '%010d', reduce { $a + $b->{left} + $b->{right} } 0, values %$all );
    print "\b" x length($cstr) unless $first;
    print $cstr;
    return $self;
}


sub _setup_logging ( $self, $test = {} ) {

    my $gll   = $self->log_level;
    my $logfn = $test->{log_file} // ( $gll ? 'STDERR' : undef );
    return unless $logfn;

    my $level_name = $test->{log_level} // $gll // 'INFO';
    my $level      = Log::Log4perl::Level::to_priority($level_name);

    if ( my $appender = Log::Log4perl->appender_by_name('app001') ) {
        my $logger = Log::Log4perl->get_logger('');
        $logger->level($level) if $logger->level ne $level;
        if ( $appender->isa('Log::Log4perl::Appender::File') and $logfn ne 'STDERR' ) {
            if ( $logfn ne $appender->filename ) {
                INFO "Switching log to '$logfn'";
                $appender->file_switch($logfn);
            }
            return;
        }
        elsif ( $appender->isa('Log::Log4perl::Appender::Screen') and $logfn eq 'STDERR' ) {
            return;
        }
    }

    my $layout =
          $ENV{HARNESS_ACTIVE}                      ? '[%P] %M(%L) %m{chomp}%n'
        : $test->{log_layout} // $logfn eq 'STDERR' ? '[%P] %m{chomp}%n'
        :                                             '%d{ISO8601} %p [%P] (%M) %m{chomp}%n';

    Log::Log4perl->easy_init( {
        file   => $logfn,
        level  => $level,
        layout => $layout,
    } );

    $SIG{__WARN__} = sub { WARN @_ };

    return;
}


1;

=head1 NAME

Spreadsheet::Compare - Module for comparing spreadsheet-like datasets

=head1 SYNOPSIS

  use Spreadsheet::Compare;
  my $cfg = {
      type     => 'CSV',
      title    => 'Test 01',
      files    => ['left.csv', 'right.csv'],
      identity => ['RowId'],
  }
  Spreadsheet::Compare->new(config => $cfg)->run();

  or

  Spreadsheet::Compare->new->config($cfg)->run;

=head1 DESCRIPTION

Spreadsheet::Compare analyses differences between two similar record sets.
It is designed to be used for regression testing of a large number of files,
databases or spreadsheets.

The record sets can be read from a variety of different sources like CSV files,
fixed column input, databases, Excel or Open/Libre Office Spreadsheets.

The differences can be saved in XLSX or HTML format and are visually highlighted
to allow fast access to the relevant parts.

Configuration of a single comparison, sets of comparisons or whole suites
can be defined as YAML configuration files in order to persist a setup that can be run
multiple times.

Spreadsheet::Compare is the central component normally used by executing the commandline utility
L<spreadcomp> with a configuration file. It feeds the relevant parts of the configuration data
to the reader, compare and reporting classes.

Reading is done by subclasses of L<Spreadsheet::Compare::Reader>, The actual comparison is done
by L<Spreadsheet::Compare::Single> while the reporting output is handled by subclasses of
L<Spreadsheet::Compare::Reporter>.

=head1 ATTRIBUTES

    $sc = Spreadsheet::Compare->new;

All attributes will return the Spredsheet::Compare object when called as setter to allow
method chaining.

=head2 config

    $sc->config($cfg);
    my $conf = $sc->config;

Get/Set the configuration for subsequent calls to run(). It hast to be either a hash reference
with a single comparison configuration, a reference to an array with multiple configurations or
the path to a YAML file.

=head2 errors

    say "found error: $_" for $sc->run->errors->@*;

(B<readonly>) Returns a reference to an array of error messages. These are errors that prevented a single
comparison from being executed.

=head2 exit_code;

    my $ec = $sc->run->exit_code;

(B<readonly>) Exit code, will contain the number of comparisons with detected differences
or 255 if the nuber exceeds 254.

=head2 log_level

    $sc->log_level('INFO');
    my $lev = $sc->log_level;

The global log level (valid are the strings TRACE, DEBUG, INFO, WARN, ERROR or FATAL).
Default is no logging at all. The level can also be set with the environment variable
B<C<SPREADSHEET_COMPARE_DEBUG>>. Using the attribute has precedence.

For a single comparison the log level can also be set with the C<log_level> option.

=head2 quiet

    $sc->quiet(1);
    my $is_quiet = $sc->quiet;

Suppress the line counter when using L</stdout>.

=head2 result

    my $res = $sc->run->result;
    say "$_ found $res->{$_}{diff} differences"  for sort keys %$res;

(B<readonly>) The result is a reference to a hash with the test titles as keys and the comparison
counters as result.

    {
        <title1> => {
            add   => <number of additional records on the right>,
            diff  => <number of found differences>,
            dup   => <number of duplicate rows (maximum of left and right)>,
            left  => <number of records on the left>,
            limit => <number of record with differences below set ste limits>,
            miss  => <number of records missing on the right>,
            right => <number of records on the right>,
            same  => <number of identical records>,
        },
        <title2> => {
        ...
    }

=head2 stdout

    $sc->stdout(1);
    my $use_stdout = $sc->stdout;

Report progress and results to stdout.

=head1 METHODS

C<Spreadsheet::Compare> is a L<Mojo::EventEmitter> and additionally implements the following methods.

=head2 run

Run all defined comparisons. Returns the object itself. Throws exceptions on global errors.
Exceptions during a single comparison are trapped and will be accessible via the L</errors>
attribute.


=head1 CONFIGURATION

A configuration can contain one or more comparison definitions. They have to be defined as a
single hashref or a reference to an array of hashes, each hash defining one comparison. The keys of
the hash specify the names of the options. Options that are common to all specified comparisons
can be given in a special hash with C<title> set to B<__GLOBAL__>.

An example for a very basic configuration with 2 CSV comparisons:

    [
      {
        title           => '__GLOBAL__',
        type            => 'CSV',
        rootdir         => 'my/data/dir',
        reporter        => 'XSLX',
        report_filename => '%{title}.xlsx',
      },
      {
        title   => 'all defaults',
        files   => [
          'left/simple01.csv',
          'right/simple01.csv'
        ],
        identity => ['A'],
      },
      {
        title => 'semicolon separator',
        files => [
          'left/simple02.csv',
          'right/simple02.csv',
        ],
        identity => ['A'],
        limit_abs => {
          D => '0.1',
          B => '1',
        },
        ignore => [
          'Z',
        ],
        csv_options => {
          sep_char => ';',
        },
      },
    ];

or as YAML config file

    ---
    - title: __GLOBAL__
      type: CSV
      rootdir : my/data/dir
      reporter: XLSX
      report_filename: %{title}.xlsx,
    - title : all defaults
      files :
        - left/simple01.csv
        - right/simple01.csv
      identity: [A]
    - title: semicolon separator
      files:
        - left/simple02.csv
        - right/simple02.csv
      identity: [A]
      ignore:
        - Z
      limit_abs:
        D: 0.1
        B: 1
      csv_options:
        sep_char: ';'

To define a suite of compare batches, a central config using the L</suite> option can be used.

To save unneccesary typing, configuration values can contain references to either environment
variables or other single configuration values. To use environment variables refer to them as
${<VARNAME>}, for configuration references use %{<OPTION>}. This is a simple search and
replace mechanism, so don't expect fancy things like referencing non scalar options to work.


=head1 OPTION REFERENCE

The following configuration options can be used to define a comparison. Options for Readers
are documented in L<Spreadsheet::Compare::Reader> or it's specific modules:

=over 4

=item * L<Spreadsheet::Compare::Reader::CSV> for CSV files

=item * L<Spreadsheet::Compare::Reader::DB> for database tables

=item * L<Spreadsheet::Compare::Reader::FIX> for fixed record files

=item * L<Spreadsheet::Compare::Reader::WB> for various spreadsheet formats (XLS, XLSX, ODS, ...)

=back

The the reporting options are documented in L<Spreadsheet::Compare::Reporter> or it's specific modules:

=over 4

=item * L<Spreadsheet::Compare::Reporter::XLSX> for generating XLSX reports

=item * L<Spreadsheet::Compare::Reporter::HTML> for generating static HTML reports

=back

=head2 left

  possible values: <string>
  default: 'left'

A descriptive name for the left side of the comparison

=head2 log_file

The file to write logs to.

=head2 log_level

  possible values: TRACE|DEBUG|INFO|WARN|ERROR|FATAL
  default: undef

The log level for the current comparison. To set this globally, use the -d option
when using L<spreadcomp> or set the environment variable B<C<SPREADSHEET_COMPARE_DEBUG>>.
This option takes precedence over the global options.

=head2 reporter

  possible values: <string>
  default: 'None'

Choose a reporter module (e.g. XLSX or HTML)

=head2 right

  possible values: <string>
  default: 'right'

A descriptive name for the right side of the comparison

=head2 rootdir

  possible values: <string>
  default: 0

Root directory for configuration, report or input files. Options containing relative
file names will be interpreted as relative to this directory.

=head2 suite

  possible values: <list of filenames>
  default: undef

Use a list of config files. The configurations will inherit all settings defined in
the master config file. For an example please have a look at the tests from the t directory
of the distribution.

=head2 summary

  possible values: <string>
  default: undef

Reporter engine for the summary. This will mostly be set in a global section, but can
be used to pick only selected comparisons for inclusion into the summary. You could
even specify a different summary engine for each comparison.

=head2 summary_filename

  possible values: <string>
  default: undef

Specify a summary filename. If not specified the filename will be derived from the
filename of the configuration file or the name of the calling program.

=head2 title

  possible values: <string>
  default: ''

The title of the current comparison. If not set, the title will be the title of the
current suite file or 'Untitled', followed by the current comparison count.


=head1 EVENTS

Spreadsheet::Compare is a L<Mojo::EventEmitter> and emits the same events as
L<Spreadsheet::Compare::Single> (see L<Spreadsheet::Compare::Single/EVENTS>).

B<WARNING> The events from Spreadsheet::Compare will have the title of the
single comparison as an additional second parameter. So instead of:

    $single->on(final_counters => sub ($obj, $counters) {
        # code
    });

it will be:

    $sc->on(final_counters => sub ($obj, $title, $counters) {
        # code
    });

In addition it emits the following events:

=head2 report_finished

    $sc->on(report_finished => sub ($obj, $title, $reporter_class, $report_filename) {
        say "finished writing $report_filename";
    });

Emitted after a single report is finished by the reporter

=head2 summary

    require Data::Dumper;
    $sc->on(summary => sub ($obj, $title, $counters) {
        say "next fetch for $title:", Dumper($counters);
    });

Emitted after a single comparison

=head1 LIMITING MEMORY USAGE

Per default Spreadsheet::Compare will load all records into memory before comparing them.
This maybe not the best approach in cases where the number of records is very large and
may not even fit into memory (which will terminate the perl interpreter).

There are two ways to handle these situations:

=head2 Sorted Data with option L<Spreadsheet::Compare::Reader/fetch_size>

The option L<Spreadsheet::Compare::Single/fetch_size> can be used to limit the number of
records that are read into memory at a time (for each side, so the read number is twice
the number given). For that to work the records have to sorted by the configured
L<Spreadsheet::Compare::Reader/identity> and L<Spreadsheet::Compare::Single/is_sorted>
have to be set to a true value. Possibly overlapping identity values at the borders of a
fetch will be handled correctly.

=head2 Chunking

When sorting is not an option, memory usage can be reduced by sacrificing speed using the
L</chunk> option with Readers that support this (e.g. CSV and FIX, it is not implemented
for the DB reader because sorting by identity can be done in SQL).

Chunking means that the the data will be read twice. First to determine the chunk name for
the record and keeping only that and the record location for reference. In the second pass
data will be read one chunk at a time. Since the chunk naming can be freely configured
(e.g with regular expressions) the possibilities for limiting the chunk size are numerous.

See L<Spreadsheet::Compare::Reader/chunk> for examples.

=head1 Limiting the number of records for testing configuration options

While testing the configuration of a comparison (for example finding the correct
identity, the columns you want to ignore or fine tune the limits), always comparing
whole data sets can be tedious. For sorted data this can be achieved with the option
L<Spreadsheet::Compare::Single/fetch_limit> limiting the number of fetches.

For unsorted data it is best to simply use selected subsets of the data.

=cut
