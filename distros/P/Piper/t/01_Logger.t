#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Logger module
#####################################################################

use v5.10;
use strict;
use warnings;

use Capture::Tiny qw(capture_stderr);
use Test::Most;

my $APP = "Piper::Logger";

use Piper::Logger;

delete $ENV{PIPER_VERBOSE};
delete $ENV{PIPER_DEBUG};

#####################################################################

my $LOGGER = Piper::Logger->new();
my %TEST = (
    default => Test::Segment->new(),
    'verbose = 1' => Test::Segment->new(verbose => 1),
    'verbose = 2' => Test::Segment->new(verbose => 2),
    'debug = 1' => Test::Segment->new(debug => 1),
    'debug = 2' => Test::Segment->new(debug => 2),
    'verbose = 1; debug = 1' => Test::Segment->new(verbose => 1, debug => 1),
    'verbose = 2; debug = 1' => Test::Segment->new(verbose => 2, debug => 1),
    'verbose = 2; debug = 2' => Test::Segment->new(verbose => 2, debug => 2),
);
my @ARGS = ('message', 'item1', { item2 => 'thing'});
my $OVERRIDE_EXP = $LOGGER->make_message($TEST{'verbose = 2; debug = 2'}, @ARGS);

# Test debug/verbose_level
{
    for my $type (qw(debug verbose)) {
        my $method = "$type\_level";
        subtest "$APP - $method" => sub {
            for my $test (keys %TEST) {
                is($LOGGER->$method($TEST{$test}), $TEST{$test}->$type(), $test);
 
                local $ENV{uc("PIPER_$type")} = 1;
                is($LOGGER->$method($TEST{$test}), 1, "$test - ENV override");
            }
        };
    }
}

# Test make_message
{
    subtest "$APP - make_message" => sub {
        my %EXP = (
            default => 'label: message',
            'verbose = 1' => 'path: message',
            'verbose = 2' => 'path: message ("item1", { item2 => "thing" })',
            'debug = 1' => 'label: message',
            'debug = 2' => 'label (id): message',
            'verbose = 1; debug = 1' => 'path: message',
            'verbose = 2; debug = 1' => 'path: message ("item1", { item2 => "thing" })',
            'verbose = 2; debug = 2' => 'path (id): message ("item1", { item2 => "thing" })',
        );

        for my $test (keys %TEST) {
            is(
                $LOGGER->make_message($TEST{$test}, @ARGS),
                $EXP{$test},
                $test
            );
        }
    };
}

# Test INFO
{
    subtest "$APP - INFO" => sub {
        my %EXP = map { $_ => $_ eq 'default' ? 0 : 1 } keys %TEST;

        for my $test (keys %TEST) {
            my $capture = capture_stderr {
                $LOGGER->INFO($TEST{$test}, @ARGS)
            };
            chomp $capture;
            is($capture,
                $EXP{$test} ? 'Info: '.$LOGGER->make_message($TEST{$test}, @ARGS) : '',
                $test
            );
        }

        local %ENV;
        $ENV{PIPER_VERBOSE} = 2;
        $ENV{PIPER_DEBUG} = 2;

        for my $test (keys %TEST) {
            my $capture = capture_stderr {
                $LOGGER->INFO($TEST{$test}, @ARGS)
            };
            chomp $capture;
            is($capture,
                "Info: $OVERRIDE_EXP",
                "$test - ENV override"
            );
        }
    };
}

# Test DEBUG
{
    subtest "$APP - DEBUG" => sub {
        my %EXP = map { $_ => $_ =~ /debug/ ? 1 : 0 } keys %TEST;

        for my $test (keys %TEST) {
            my $capture = capture_stderr {
                $LOGGER->DEBUG($TEST{$test}, @ARGS)
            };
            chomp $capture;
            is($capture,
                $EXP{$test} ? 'Info: '.$LOGGER->make_message($TEST{$test}, @ARGS) : '',
                $test
            );
        }

        local %ENV;
        $ENV{PIPER_VERBOSE} = 2;
        $ENV{PIPER_DEBUG} = 2;

        for my $test (keys %TEST) {
            my $capture = capture_stderr {
                $LOGGER->DEBUG($TEST{$test}, @ARGS)
            };
            chomp $capture;
            is($capture,
                "Info: $OVERRIDE_EXP",
                "$test - ENV override"
            );
        }
    };
}

# Test WARN
{
    subtest "$APP - WARN" => sub {
        for my $test (keys %TEST) {
            warning_is {
                $LOGGER->WARN($TEST{$test}, @ARGS)
            } { carped => 'Warning: '.$LOGGER->make_message($TEST{$test}, @ARGS) }, $test;
        }

        local %ENV;
        $ENV{PIPER_VERBOSE} = 2;
        $ENV{PIPER_DEBUG} = 2;

        for my $test (keys %TEST) {
            warning_is {
                $LOGGER->WARN($TEST{$test}, @ARGS)
            } { carped => "Warning: $OVERRIDE_EXP" }, "$test - ENV override";
        }
    };
}

# Test ERROR
{
    subtest "$APP - ERROR" => sub {
        for my $test (keys %TEST) {
            dies_ok {
                $LOGGER->ERROR($TEST{$test}, @ARGS)
            } "$test died";

            my $message = 'Error: '.$LOGGER->make_message($TEST{$test}, @ARGS);
            like($@, qr/^\Q$message\E/, "$test message");
        }

        local %ENV;
        $ENV{PIPER_VERBOSE} = 2;
        $ENV{PIPER_DEBUG} = 2;

        for my $test (keys %TEST) {
            dies_ok {
                $LOGGER->ERROR($TEST{$test}, @ARGS)
            } "$test (ENV override) died";
 
            like($@, qr/^Error: \Q$OVERRIDE_EXP\E/, "$test (ENV override) message");
        }
    };
}

#####################################################################

done_testing();

BEGIN {
    package Test::Segment;

    use Moo;

    has path => (
        is => 'ro',
        default => 'path',
    );

    has label => (
        is => 'ro',
        default => 'label',
    );

    has id => (
        is => 'ro',
        default => 'id',
    );

    has verbose => (
        is => 'ro',
        default => 0,
    );

    has debug => (
        is => 'ro',
        default => 0,
    );
}
