#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::filetest';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $sopm = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP', 'TestSMTP.sopm' );



my @tests = (
    { size => '100', fail => 1 },
    { size => '1k', fail => 0 },
    { size => '1K', fail => 0 },
    { size => '1m', fail => 0 },
    { size => '1M', fail => 0 },
    { size => '1g', fail => 0 },
    { size => '1G', fail => 0 },
);


for my $test ( @tests ) {
    local $ENV{OPM_MAX_SIZE} = $test->{size};

    my $exec_output;

    eval {
        OPM::Maker::Command::filetest::execute( undef, {}, [ $sopm ] );
        1;
    } or $exec_output = $@;

    if ( $test->{fail} ) {
        like $exec_output, qr/TestSMTP\.sopm too big \(max size: 100 bytes\)/;
    }
    else {
        is $exec_output, undef;
    }
}

done_testing();
