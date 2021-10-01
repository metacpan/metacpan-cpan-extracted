#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Spec::Functions qw(rel2abs catdir catfile);
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::dependencies';

my $dir = rel2abs( catdir( dirname( __FILE__ ), qw/.. valid SecondSMTP/ ) );
my $opm = catfile( $dir, 'SecondSMTP-0.0.1.opm' );



my @tests = (
    { size => '100', fail => 1 },
    { size => '1k', fail => 1 },
    { size => '1K', fail => 1 },
    { size => '1m', fail => 0 },
    { size => '1M', fail => 0 },
    { size => '1g', fail => 0 },
    { size => '1G', fail => 0 },
);


for my $test ( @tests ) {
    local $ENV{OPM_MAX_SIZE} = $test->{size};

    my $exec_output;

    eval {
        OPM::Maker::Command::dependencies::execute( undef, {}, [ $opm ] );
        1;
    } or $exec_output = $@;

    if ( $test->{fail} ) {
        like $exec_output, qr/SecondSMTP-0\.0\.1\.opm too big \(max size: 1[0-9]{2,3} bytes\)/;
    }
    else {
        is $exec_output, undef;
    }
}

done_testing();
