package TAP::Formatter::JUnit::Session;

use Moose;
use MooseX::NonMoose;
extends qw(
    TAP::Formatter::Console::Session
);

use Storable qw(dclone);
use File::Path qw(mkpath);
use IO::File;
use TAP::Formatter::JUnit::Result;
use namespace::clean;

has 'testcases' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => [qw( Array )],
    handles => {
        add_testcase  => 'push',
        num_testcases => 'count',
    },
);

has 'passing_todo_ok' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has '_queue' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => [qw( Array )],
    handles => {
        _queue_add => 'push',
    },
);

###############################################################################
# Subroutine:   _initialize($arg_for)
###############################################################################
# Custom initializer, so we can accept a new "passing_todo_ok" argument at
# instantiation time.
sub _initialize {
    my ($self, $arg_for) = @_;
    $arg_for ||= {};

    my $passing_todo_ok = delete $arg_for->{passing_todo_ok};
    $self->passing_todo_ok($passing_todo_ok);

    return $self->SUPER::_initialize($arg_for);
}

###############################################################################
# Subroutine:   result($result)
###############################################################################
# Called by the harness for each line of TAP it receives.
#
# Queues up all of the TAP output for later conversion to JUnit.
sub result {
    my ($self, $result) = @_;

    # except for a few things we don't want to process as a "test case", add
    # the test result to the queue.
    unless (    ($result->raw() =~ /^# Looks like you failed \d+ tests? of \d+/)
             || ($result->raw() =~ /^# Looks like you planned \d+ tests? but ran \d+/)
             || ($result->raw() =~ /^# Looks like your test died before it could output anything/)
           ) {
        my $wrapped = TAP::Formatter::JUnit::Result->new(
            'time'   => $self->get_time,
            'result' => $result,
        );
        $self->_queue_add($wrapped);
    }
}

###############################################################################
# Subroutine:   close_test()
###############################################################################
# Called to close the test session.
#
# Flushes the queue if we've got anything left in it, dumps the JUnit to disk
# (if necessary), and adds the XML for this test suite to our formatter.
sub close_test {
    my $self   = shift;
    my $xml    = $self->xml;
    my $parser = $self->parser;

    # Process the queued up TAP stream
    my $is_first      = 1;
    my $t_start       = $self->parser->start_time;
    my $t_last_test   = $t_start;
    my $timer_enabled = $self->formatter->timer;

    my $queue = $self->_queue;
    my $index = 0;
    while ($index < @{$queue}) {
        my $result = $queue->[$index++];

        # First line of output generates the "init" timing.
        if ($is_first) {
            if ($timer_enabled) {
                unless ($result->is_test) {
                    my $duration = $result->time - $t_start;
                    my $case     = $xml->testcase( {
                        'name' => _squeaky_clean('(init)'),
                        'time' => $duration,
                    } );
                    $self->add_testcase($case);
                    $t_last_test = $result->time;
                }
            }
            $is_first = 0;
        }

        # Test output
        if ($result->is_test) {
            # how long did it take for this test?
            my $duration = $result->time - $t_last_test;

            # slurp in all of the content up until the next test
            my $content = $result->as_string;
            while ($index < @{$queue}) {
                last if ($queue->[$index]->is_test);
                last if ($queue->[$index]->is_plan);

                my $stuff = $queue->[$index++];
                $content .= "\n" . $stuff->as_string;
            }

            # create a failure/error element if the test was bogus
            my $failure;
            my $bogosity = $self->_check_for_test_bogosity($result);
            if ($bogosity) {
                my $cdata = $self->_cdata($content);
                my $level = $bogosity->{level};
                $failure  = $xml->$level( {
                    type    => $bogosity->{type},
                    message => $bogosity->{message},
                }, $cdata );
            }

            # add this test to the XML stream
            my $case = $xml->testcase(
                {
                    'name' => _get_testcase_name($result),
                    (
                        $timer_enabled ? ('time' => $duration) : ()
                    ),
                },
                $failure,
            );
            $self->add_testcase($case);

            # update time of last test seen
            $t_last_test = $result->time;
        }
    }

    # track time for teardown, if needed
    if ($timer_enabled) {
        my $duration = $self->parser->end_time - $queue->[-1]->time;
        my $case     = $xml->testcase( {
            'name' => _squeaky_clean('(teardown)'),
            'time' => $duration,
        } );
        $self->add_testcase($case);
    }

    # collect up all of the captured test output
    my $captured = join '', map { $_->raw . "\n" } @{$queue};

    # if the test died unexpectedly, make note of that
    my $die_msg;
    my $exit = $parser->exit();
    if ($exit) {
        my $wstat = $parser->wait();
        my $status = sprintf("%d (wstat %d, 0x%x)", $exit, $wstat, $wstat);
        $die_msg  = "Dubious, test returned $status";
    }

    # add system-out/system-err data, as raw CDATA
    my $sys_out = 'system-out';
    $sys_out = $xml->$sys_out($captured ? $self->_cdata($captured) : undef);

    my $sys_err = 'system-err';
    $sys_err = $xml->$sys_err($die_msg ? $self->_cdata("$die_msg\n") : undef);

    # update the testsuite with aggregate info on this test suite
    #
    # tests     - total number of tests run
    # time      - wallclock time taken for test run (floating point)
    # failures  - number of tests that we detected as failing
    # errors    - number of errors:
    #               - passing TODOs
    #               - if a plan was provided, mismatch between that and the
    #                 number of actual tests that were run
    #               - either "no plan was issued" or "test died" (a dying test
    #                 may not have a plan issued, but should still be considered
    #                 a single error condition)
    my $testsrun = $parser->tests_run() || 0;
    my $time     = $parser->end_time() - $parser->start_time();
    my $failures = $parser->failed();

    my $noplan   = $parser->plan() ? 0 : 1;
    my $planned  = $parser->tests_planned() || 0;

    my $num_errors = 0;
    $num_errors += $parser->todo_passed() unless $self->passing_todo_ok();
    $num_errors += abs($testsrun - $planned) if ($planned);

    my $suite_err;
    if ($die_msg) {
        $suite_err = $xml->error( { message => $die_msg } );
        $num_errors ++;
    }
    elsif ($noplan) {
        $suite_err = $xml->error( { message => 'No plan in TAP output' } );
        $num_errors ++;
    }
    elsif ($planned && ($testsrun != $planned)) {
        $suite_err = $xml->error( { message => "Looks like you planned $planned tests but ran $testsrun." } );
    }

    my @tests = @{$self->testcases()};
    my %attrs = (
        'name'     => _get_testsuite_name($self),
        'tests'    => $testsrun,
        'failures' => $failures,
        'errors'   => $num_errors,
        (
            $timer_enabled ? ('time' => $time) : ()
        ),
    );
    my $testsuite = $xml->testsuite(\%attrs, @tests, $sys_out, $sys_err, $suite_err);
    $self->formatter->add_testsuite($testsuite);
    $self->dump_junit_xml($testsuite);
}

###############################################################################
# Subroutine:   dump_junit_xml($testsuite)
###############################################################################
# Dumps the JUnit for the given XML '$testsuite', to the directory specified by
# 'PERL_TEST_HARNESS_DUMP_TAP'.
sub dump_junit_xml {
    my ($self, $testsuite) = @_;
    if (my $spool_dir = $ENV{PERL_TEST_HARNESS_DUMP_TAP}) {
        my $spool = File::Spec->catfile($spool_dir, $self->name() . '.junit.xml');

        # clone the testsuite; XML::Generator only lets us auto-vivify the
        # CDATA sections *ONCE*.
        $testsuite = dclone($testsuite);

        # create target dir
        my ($vol, $dir, undef) = File::Spec->splitpath($spool);
        my $path = File::Spec->catpath($vol, $dir, '');
        mkpath($path);

        # create JUnit XML, and dump to disk
        my $junit = $self->xml->xml($self->xml->testsuites($testsuite) );
        my $fout  = IO::File->new( $spool, '>:utf8' )
            || die "Can't write $spool ( $! )\n";
        $fout->print($junit);
        $fout->close();
    }
}

###############################################################################
# Subroutine:   xml()
###############################################################################
# Returns a new 'XML::Generator' to generate XML output.  This is simply a
# shortcut to '$self->formatter->xml()'.
sub xml {
    my $self = shift;
    return $self->formatter->xml();
}

###############################################################################
# Checks for bogosity in the test result.
sub _check_for_test_bogosity {
    my $self   = shift;
    my $result = shift;

    if ($result->todo_passed() && !$self->passing_todo_ok()) {
        return {
            level   => 'error',
            type    => 'TodoTestSucceeded',
            message => $result->explanation(),
        };
    }

    if ($result->is_unplanned()) {
        return {
            level   => 'error',
            type    => 'UnplannedTest',
            message => $result->as_string(),
        };
    }

    if (not $result->is_ok()) {
        return {
            level   => 'failure',
            type    => 'TestFailed',
            message => $result->as_string(),
        };
    }

    return;
}

###############################################################################
# Generates the name for a test case.
sub _get_testcase_name {
    my $test = shift;
    my $name = join(' ', $test->number(), _clean_test_description($test));
    $name =~ s/\s+$//;
    return $name;
}

###############################################################################
# Generates the name for the entire test suite.
sub _get_testsuite_name {
    my $self = shift;
    my $name = $self->name;
    $name =~ s{^\./}{};
    $name =~ s{^t/}{};
    return _clean_to_java_class_name($name);
}

###############################################################################
# Cleans up the given string, removing any characters that aren't suitable for
# use in a Java class name.
sub _clean_to_java_class_name {
    my $str = shift;
    $str =~ s/[^-:_A-Za-z0-9]+/_/gs;
    return $str;
}

###############################################################################
# Cleans up the description of the given test.
sub _clean_test_description {
    my $test = shift;
    my $desc = $test->description();
    return _squeaky_clean($desc);
}

###############################################################################
# Creates a CDATA block for the given data (which is made squeaky clean first,
# so that JUnit parsers like Hudson's don't choke).
sub _cdata {
    my ($self, $data) = @_;
    $data = _squeaky_clean($data);
    return $self->xml->xmlcdata($data);
}

###############################################################################
# Clean a string to the point that JUnit can't possibly have a problem with it.
sub _squeaky_clean {
    my $string = shift;
    # control characters (except CR and LF)
    $string =~ s/([\x00-\x09\x0b\x0c\x0e-\x1f])/"^".chr(ord($1)+64)/ge;
    # high-byte characters
    $string =~ s/([\x7f-\xff])/'[\\x'.sprintf('%02x',ord($1)).']'/ge;
    return $string;
}

1;

=for stopwords instantiation testcases

=head1 NAME

TAP::Formatter::JUnit::Session - Harness output delegate for JUnit output

=head1 DESCRIPTION

C<TAP::Formatter::JUnit::Session> provides JUnit output formatting for
C<TAP::Harness>.

=head1 METHODS

=over

=item _initialize($arg_for)

Over-ridden private initializer, so we can accept a new "passing_todo_ok"
argument at instantiation time.

=item result($result)

Called by the harness for each line of TAP it receives.

Internally, all of the TAP is added to a queue until we hit the start of
the "next" test (at which point we flush the queue. This allows us to
capture any error output or diagnostic info that comes after a test
failure.

=item close_test()

Called to close the test session.

Flushes the queue if we've got anything left in it, dumps the JUnit to disk
(if necessary), and adds the XML for this test suite to our formatter.

=item dump_junit_xml($testsuite)

Dumps the JUnit for the given XML C<$testsuite>, to the directory specified
by C<PERL_TEST_HARNESS_DUMP_TAP>.

=item add_testcase($case)

Adds an XML test C<$case> to the list of testcases we've run in this
session.

=item xml()

Returns a new C<XML::Generator> to generate XML output. This is simply a
shortcut to C<$self-E<gt>formatter-E<gt>xml()>.

=back

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

=head1 COPYRIGHT

Copyright 2008-2010, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<TAP::Formatter::JUnit>.

=cut
