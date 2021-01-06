#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 4;
use TAP::Harness;
use IO::Scalar;
use File::Slurp qw(write_file);

###############################################################################
# When timer is disabled, we should have *NO* timer info in the JUnit output.
timer_disabled: {
    my $test     = qq|
        use Test::More tests => 1;
        pass 'no timing in this test';
    |;
    my $results = run_test($test, {
        timer => 0,
    } );
    ok $results, 'got JUnit';
    unlike $results, qr/time/ism, '... without any timing information';
}

###############################################################################
# When timer is enabled, JUnit output *should* have timer info in it.
timer_enabled: {
    my $test     = qq|
        use Test::More tests => 2;
        pass 'one';
        pass 'two';
    |;
    my $results = run_test($test, {
        timer => 1,
    } );
    ok $results, 'got JUnit';
    like $results, qr/time/ism, '... with timing information';
}

sub run_test {
    my $code = shift;
    my $opts = shift;
    my $file = "test-$$.t";

    my $junit = undef;
    my $fh    = IO::Scalar->new(\$junit);
    my $harness = TAP::Harness->new( {
        formatter_class => 'TAP::Formatter::JUnit',
        stdout          => $fh,
        %{$opts},
    } );

    write_file($file, $code);
    $harness->runtests($file);
    unlink $file;

    return $junit;
}
