#!perl

use strict;
use warnings;
use UNIVERSAL qw(isa);
use lib '../lib';
use Test::More tests => 5;
use Test::CallFlow qw(:all);    # package under test

package Foo;
use vars qw($original_called);

sub mockable { "real sub called " . ++$original_called . " times" }

package main;

mock_package('Foo');
record_calls_from('RecordTests');

is( Test::CallFlow::instance()->{state},
    $Test::CallFlow::state{record},
    "Recording state activated" );

package RecordTests;

sub test_recording {
    Foo::mockable;
}

package main;

my $out = RecordTests::test_recording();
is( $out,
    "real sub called 1 times",
    "Call through recording mock returns value from real call" );

my $plan = join ";\n", map { $_->name } mock_plan()->list_calls();

like(
    $plan,
    qr/Foo::mockable->result\('real sub called 1 times'\)(?x)
        ->called_from\('RecordTests::test_recording
        (?-x) at \S*05-recording.t line \d+'\)/,
    , "Recorded call plan looks right"
);
mock_reset();
mock_run();

$out = RecordTests::test_recording();
is( $out,
    "real sub called 1 times",
    "Call to recorded mock returns a recorded value" );

mock_end();
mock_clear();

$out = RecordTests::test_recording();
is( $out,
    "real sub called 2 times",
    "Call after mock_clear goes to original sub" );
