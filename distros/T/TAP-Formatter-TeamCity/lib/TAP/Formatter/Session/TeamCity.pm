package TAP::Formatter::Session::TeamCity;

use strict;
use warnings;

our $VERSION = '0.13';

use TAP::Parser::Result::Test;
use TeamCity::Message qw( tc_message );

use base qw( TAP::Formatter::Session );

{
    my @accessors = map { '_tc_' . $_ } qw(
        last_test_name
        last_test_result
        last_suite_is_empty
        suite_name_stack
        test_output_buffer
        suite_output_buffer
        buffered_output
        output_handle
    );
    __PACKAGE__->mk_methods(@accessors);
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _initialize {
    my $self = shift;

    $self->SUPER::_initialize(@_);

    $self->_tc_suite_name_stack( [] );
    $self->_tc_test_output_buffer(q{});
    $self->_tc_suite_output_buffer(q{});

    my $buffered = q{};
    $self->_tc_buffered_output( \$buffered );

    if ( $self->_is_parallel ) {
        $self->_tc_message(
            'progressMessage',
            'starting ' . $self->name,
            1,
        );

        ## no critic (InputOutput::RequireCheckedOpen, InputOutput::RequireCheckedSyscalls)
        open my $fh, '>', \$buffered;
        $self->_tc_output_handle($fh);
    }
    else {
        $self->_tc_output_handle( \*STDOUT );
    }

    $self->_start_suite( $self->name );

    return $self;
}
## use critic

sub _is_parallel {
    return $_[0]->formatter->jobs > 1;
}

sub result {
    my $self   = shift;
    my $result = shift;

    my $type    = $result->type;
    my $handler = "_handle_$type";

    die qq{Can't handle result of type=$type}
        unless $self->can($handler);

    $self->$handler($result);
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _handle_test {
    my $self   = shift;
    my $result = shift;

    unless ( $self->_test_finished ) {
        if ( $result->directive eq 'SKIP' ) {

            # when tcm skips methods, we get 1st a Subtest message
            # then "ok $num # skip $message"
            ( my $reason ) = ( $result->raw =~ /^\s*ok [0-9]+ # skip (.*)$/ );

            $self->_tc_message(
                'testStarted',
                {
                    name                  => 'Skipped',
                    captureStandardOutput => 'true'
                }
            );
            $self->_tc_message(
                'testIgnored',
                {
                    name    => 'Skipped',
                    message => $reason
                },
            );
            $self->_finish_test('Skipped');
            $self->_finish_suite;
            return;
        }
    }

    my $test_name = $self->_compute_test_name($result);

    $self->_test_started($result) unless $self->_finish_suite($test_name);
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _handle_comment {
    my $self   = shift;
    my $result = shift;

    my $comment = $result->raw;

    # Always pass TC messages through immediately.
    if ( $comment =~ /^##teamcity\[/ ) {
        my $handle = $self->_tc_output_handle;
        print STDOUT $comment, "\n" or die $!;
        return;
    }

    if ( $comment =~ /^\s*# Looks like you failed [0-9]+/ ) {
        $self->_test_finished;
        return;
    }
    $comment =~ s/^\s*#\s?//;
    $comment =~ s/\s+$//;
    return unless $comment =~ /\S/;
    $self->_append_to_tc_test_output_buffer("$comment\n");
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines, Subroutines::ProhibitExcessComplexity)
#
# This method will be called for all subtest output. The default TAP formatter
# we're subclassing cannot parse subtests at all, and it basically ignores all
# lines with leading spaces, treating them as unknown content. We, however,
# need to parse that output in order to generate the relevant TC events.
sub _handle_unknown {
    my $self   = shift;
    my $result = shift;

    my $raw = $result->raw;

    # We are starting a new subtest. This is a note emitted by Test::Builder
    # at the beginning of each subtest. It simply consists of "Subtest:
    # $name".
    if ( $raw =~ /^\s*# Subtest: (.*)$/ ) {
        $self->_test_finished;
        $self->_start_suite($1);

        # We want progress messages for each top-level subtest, but not for
        # any subtests they might contain.
        if ( $self->_is_parallel && @{ $self->_tc_suite_name_stack } == 2 ) {
            my $name = join q{ - }, @{ $self->_tc_suite_name_stack };
            $self->_tc_message(
                'progressMessage',
                "starting $name",
                1,
            );
        }
    }

    # This is a test result inside a subtest.
    elsif ( $raw =~ /^\s*(not )?ok ([0-9]+)( - (.*))?$/ ) {
        my $is_ok     = !$1;
        my $test_num  = $2;
        my $test_name = $4;
        $self->_test_finished;
        $test_name = 'NO TEST NAME' unless defined $test_name;

        my $todo;
        if ( $test_name =~ s/ # TODO (.+)$// ) {
            $todo = $1;
        }

        unless ( $self->_finish_suite($test_name) ) {
            my $ok = $is_ok || $todo ? 'ok' : 'not ok';
            my $actual_result = TAP::Parser::Result::Test->new(
                {
                    'ok'          => $ok,
                    'explanation' => $todo // q{},
                    'directive'   => $todo ? 'TODO' : q{},
                    'type'        => 'test',
                    'test_num'    => $test_num,
                    'description' => "- $test_name",
                    'raw'         => "$ok $test_num - $test_name",
                }
            );
            $self->_test_started($actual_result);
        }
    }

    # This is a skipped test.
    elsif ( $raw =~ /^\s+ok [0-9]+ # skip (.*)$/
        && !$self->_tc_last_test_result ) {

        # when tcm skips methods, we get 1st a Subtest message
        # then "ok $num # skip $message"
        my $reason = $1;
        $self->_tc_message(
            'testStarted',
            {
                name                  => 'Skipped',
                captureStandardOutput => 'true'
            },
        );
        $self->_tc_message(
            'testIgnored',
            {
                name    => 'Skipped',
                message => $reason,
            },
        );
        $self->_finish_test('Skipped');
        $self->_finish_suite;
    }

    # I'm not sure how this could ever happen, but it seems like it can under
    # Test::Class::Moose. The "Looks like you failed ..."  message should only
    # happen when a process exits, not when a subtest finishes.
    elsif ( $raw =~ /^\s*# Looks like you failed [0-9]+/ ) {
        $self->_test_finished;
    }

    # This is a note or diag inside the subtest.
    elsif ( $raw =~ /^\s*#/ ) {
        ( my $clean_raw = $raw ) =~ s/^\s*#\s?//;
        $clean_raw =~ s/\s+$//;
        return unless $clean_raw =~ /\S/;

        # If we have a test in the buffer, then this diagnostic message
        # applies to that test.
        if ( $self->_tc_last_test_result ) {

            # I think this should actually be appended to the test output
            # buffer, but that output can get eaten when a subtest dies. For
            # now we'll just turn this into a generic TC message.
            $self->_tc_message(
                'message',
                { text => $clean_raw },
            );
        }

        # Otherwise it applies to the most recent subtest (or the .t file
        # itself).
        else {
            $self->_append_to_tc_suite_output_buffer("$clean_raw\n");
        }
    }

    # This is noise from Devel::Cover that we don't want to throw out
    # entirely, but also should not affect the test status either.
    elsif ( $raw =~ qr/Deep recursion on subroutine "B::Deparse/ ) {
        $self->_tc_message(
            'message',
            { text => $raw },
        );
    }

    # This is a test count from TAP. We don't care about that.
    elsif ( $raw =~ /^\s+[0-9]+\.\.[0-9]+$/ ) {
        return;
    }

    # Anything else might be random non-TAP output. We want to capture it and
    # make sure it's emitted in the TC results if it is.
    elsif ( $raw =~ /\S/ ) {
        $self->_append_to_tc_suite_output_buffer($raw);
    }
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _handle_plan {
    my $self   = shift;
    my $result = shift;

    unless ( $self->_test_finished ) {
        if ( $result->directive eq 'SKIP' ) {
            $self->_tc_message(
                'testStarted',
                {
                    name                  => 'Skipped',
                    captureStandardOutput => 'true',
                },
            );
            $self->_tc_message(
                'testIgnored',
                {
                    name    => 'Skipped',
                    message => $result->explanation,
                },
            );
            $self->_finish_test('Skipped');
        }
    }
}

sub _test_started {
    my $self   = shift;
    my $result = shift;

    my $test_name = $self->_compute_test_name($result);
    $self->_tc_message(
        'testStarted',
        {
            name                  => $test_name,
            captureStandardOutput => 'true',
        },
    );
    $self->_tc_last_test_name($test_name);
    $self->_tc_last_test_result($result);
}

sub _test_finished {
    my $self = shift;

    return unless $self->_tc_last_test_result;
    $self->_emit_teamcity_test_results(
        $self->_tc_last_test_name,
        $self->_tc_last_test_result
    );
    $self->_finish_test( $self->_tc_last_test_name );
    return 1;
}

sub _emit_teamcity_test_results {
    my $self      = shift;
    my $test_name = shift;
    my $result    = shift;

    my $buffer = $self->_tc_test_output_buffer;
    $self->_tc_test_output_buffer(q{});
    chomp $buffer;

    if ( $result->has_todo || $result->has_skip ) {
        $self->_tc_message(
            'testIgnored',
            {
                name    => $test_name,
                message => $result->explanation,
            },
        );
        return;
    }

    return if $result->is_ok;

    $self->_tc_message(
        'testFailed',
        {
            name    => $test_name,
            message => 'not ok',
            ( $buffer ? ( details => $buffer ) : () ),
        },
    );
}

sub _compute_test_name {
    my $self   = shift;
    my $result = shift;

    my $description = $result->description;
    my $test_name = $description eq q{} ? $result->explanation : $description;
    $test_name =~ s/^-\s//;
    $test_name = 'NO TEST NAME' if $test_name eq q{};
    return $test_name;
}

sub _finish_test {
    my $self      = shift;
    my $test_name = shift;

    $self->_tc_message( 'testFinished', { name => $test_name } );
    $self->_tc_last_test_name(undef);
    $self->_tc_last_test_result(undef);
    $self->_tc_last_suite_is_empty(0);
}

sub _start_suite {
    my $self       = shift;
    my $suite_name = shift;

    push @{ $self->_tc_suite_name_stack }, $suite_name;
    $self->_tc_last_suite_is_empty(1);
    $self->_tc_message( 'testSuiteStarted', { name => $suite_name } );
}

sub close_test {
    my $self = shift;

    if ( $self->_tc_test_output_buffer
        =~ /^\QTests were run but no plan was declared and done_testing() was not seen.\E$/m
        ) {
        $self->_recover_from_catastrophic_death;
    }
    else {
        if ( !$self->_test_finished && $self->_tc_suite_output_buffer ) {
            $self->_test_started( $self->_test_died_result_object );
            $self->_tc_test_output_buffer( $self->_tc_suite_output_buffer );
            $self->_tc_suite_output_buffer(q{});
            $self->_test_finished;
        }
        {
            my @copy = @{ $self->_tc_suite_name_stack };
            $self->_finish_suite for @copy;
        }
    }

    if ( $self->_is_parallel ) {
        print ${ $self->_tc_buffered_output }
            or die $!;
    }
}

sub _recover_from_catastrophic_death {
    my $self = shift;

    if ( $self->_tc_last_test_result ) {
        my $test_num    = $self->_tc_last_test_result->number;
        my $description = $self->_tc_last_test_result->description;
        $self->_tc_last_test_result(
            TAP::Parser::Result::Test->new(
                {
                    'ok'          => 'not ok',
                    'explanation' => q{},
                    'directive'   => q{},
                    'type'        => 'test',
                    'test_num'    => $test_num,
                    'description' => "- $description",
                    'raw'         => "not ok $test_num - $description",
                }
            )
        );
    }
    else {
        $self->_test_started( $self->_test_died_result_object );
    }
    $self->_test_finished;
    {
        my @copy = @{ $self->_tc_suite_name_stack };
        $self->_finish_suite for @copy;
    }
}

sub _finish_suite {
    my $self = shift;
    my $name = shift;

    return 0 unless @{ $self->_tc_suite_name_stack };

    $name //= $self->_tc_suite_name_stack->[-1];

    return 0 unless $name eq $self->_tc_suite_name_stack->[-1];

    if ( $self->_tc_last_suite_is_empty ) {
        $self->_test_started( $self->_test_died_result_object );
        $self->_tc_test_output_buffer( $self->_tc_suite_output_buffer );
        $self->_tc_suite_output_buffer(q{});
        $self->_test_finished;
    }
    pop @{ $self->_tc_suite_name_stack };
    $self->_tc_suite_output_buffer(q{});
    $self->_tc_last_suite_is_empty(0);
    $self->_tc_message( 'testSuiteFinished', { name => $name } );

    return 1;
}

sub _append_to_tc_test_output_buffer {
    my $self   = shift;
    my $output = shift;

    $self->_tc_test_output_buffer( $self->_tc_test_output_buffer . $output );

    return;
}

sub _append_to_tc_suite_output_buffer {
    my $self   = shift;
    my $output = shift;

    $self->_tc_suite_output_buffer(
        $self->_tc_suite_output_buffer . $output );

    return;
}

sub _test_died_result_object {

    # We used to try to figure out whether we died in a subtest or the top
    # level test for the .t file by looking at the size of the test suite
    # stack, but there's really no reliable way to figure that out with the
    # information we have available. That means we just have to use this
    # fairly generic test name instead of something like 'Test died in a
    # subtest'.
    my $test_name = 'Test died';
    return TAP::Parser::Result::Test->new(
        {
            'ok'          => 'not ok',
            'explanation' => q{},
            'directive'   => q{},
            'type'        => 'test',
            'test_num'    => 1,
            'description' => "- $test_name",
            'raw'         => "not ok 1 - $test_name",
        }
    );
}

sub _tc_message {
    my $self         = shift;
    my $type         = shift;
    my $content      = shift;
    my $force_stdout = shift;

    if ( ref $content ) {
        $content->{flowId} ||= $self->name;
    }

    my $handle = $force_stdout ? \*STDOUT : $self->_tc_output_handle;
    print {$handle} tc_message(
        type    => $type,
        content => $content,
    ) or die $!;

    return;
}

1;

__END__

=pod

=head1 DESCRIPTION

This module provides the core internals for turning TAP into TeamCity
messages. There are no user-serviceable parts in here.

=cut
