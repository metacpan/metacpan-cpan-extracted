#!perl

use strict;
use warnings;

use File::Spec;
use Test::More;
use Test::Compile::Internal;

plan skip_all => "I don't know how to redirect STDERR on your crazy OS"
    unless $^O =~ m/linux|.*bsd|solaris|darwin/;


sub makeAnError {
    my ($verbose, $file) = @_;

    my $internal = Test::Compile::Internal->new();
    $internal->verbose($verbose);

    # Might output "$0 syntax OK" to STDERR
    $internal->pl_file_compiles($file);
}

sub main {
    my (@args) = @_;

    if ( @args ) {
        my $verbose;
        my $file = $0;
        if ( $args[0] =~ m/silent/ ) {
            $verbose = 0;
        }
        if ( $args[0] =~ m/verbose/ ) {
            $verbose = 1;
        }
        if ( $args[1] =~ m/failure/ ) {
            $file = 't/scripts/failure.pl';
        }
        makeAnError($verbose, $file);
        return;
    }

    # Test that the accessor functionality works
    my $test_object = Test::Compile::Internal->new();
    is($test_object->verbose(), undef, "verbosity defaults to undef");

    $test_object->verbose(1);
    is($test_object->verbose(), 1, "setting verbosity to 1 is stored in the object");

    $test_object->verbose(0);
    is($test_object->verbose(), 0, "setting verbosity to 0 is stored in the object");

    $test_object->verbose(undef);
    is($test_object->verbose(), undef, "setting verbosity to undef is stored in the object");

    # Test that the verbosity setting is honoured
    my $tests = [
        # verbosity, script,    expect_output, expect_executing 
        ['default', 'success', 'no output',    0],
        ['default', 'failure', 'output',       0],
        ['silent',  'success', 'no output',    0],
        ['silent',  'failure', 'no output',    0],
        ['verbose', 'success', 'output',       1],
        ['verbose', 'failure', 'output',       1],
    ];

    local $ENV{PERL5LIB} = join(":",@INC);
    for my $test ( @$tests ) {
	# Given
        my ($verbosity, $script, $expect_output, $expect_executing) = @$test;
        my $cmd = "$^X $0 $verbosity $script";

	# When
        my @output = `$cmd 2>&1`;

        my $found_executing = 0;
        for my $line ( @output ) {
            if ( $line =~ qr/Executing: / ) {
                $found_executing = 1;
            }
        }

	# Then
        is($found_executing, $expect_executing, "$verbosity Executing: $found_executing");

        if ( $expect_output eq "output" ) {
            isnt(@output, 0, "Got output for $verbosity/$script");
        } else {
            is(@output, 0, "no output for $verbosity/$script");
        }
    }


    done_testing();
}

main(@ARGV) unless caller;
