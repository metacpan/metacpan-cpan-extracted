#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::index';

my $dir     = File::Spec->rel2abs( dirname __FILE__ );
my $opm_dir = File::Spec->catdir( $dir, '..', 'repo' );

my @tests = (
    { size => '15000', fail => 1 },
    { size => '15k', fail => 1 },
    { size => '15K', fail => 1 },
    { size => '15m', fail => 0 },
    { size => '15M', fail => 0 },
    { size => '15g', fail => 0 },
    { size => '15G', fail => 0 },
);


for my $test ( @tests ) {
    local $ENV{OPM_MAX_SIZE} = $test->{size};

    my $exec_output;

    eval {
        OPM::Maker::Command::index::execute( undef, {}, [ $opm_dir ] );
        1;
    } or $exec_output = $@;

    if ( $test->{fail} ) {
        like $exec_output, qr/SecondSMTP-0\.0\.1\.opm too big \(max size: 15[0-9]{3} bytes\)/;
    }
    else {
        is $exec_output, undef;
    }
}

done_testing();
