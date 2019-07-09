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
        ['default', 'success', 'no output'],
        ['default', 'failure', 'output'],
        ['silent',  'success', 'no output'],
        ['silent',  'failure', 'no output'],
        ['verbose', 'success', 'output'],
        ['verbose', 'failure', 'output'],
    ];

    local $ENV{PERL5LIB} = join(":",@INC);
    for my $test ( @$tests ) {
        my $cmd = "$^X $0 $test->[0] $test->[1]";
        my $output = `$cmd 2>&1`;
        my $name = "verbose: $test->[0], script: $test->[1], should produce: $test->[2]";
        if ( $test->[2] eq "output" ) {
            isnt($output, "", $name);
        } else {
            is($output, "", $name);
        }
    }

    done_testing();
}

main(@ARGV) unless caller;
