#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Copy qw(copy);
use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::filetest';

my $dir  = File::Spec->catdir( dirname( __FILE__ ), 'TestSMTP' );

my $file = 'opmbuild_filetest_ignore';
copy $dir . '/' . $file, $dir . '/.' . $file;

my $sopm = File::Spec->catfile( $dir, 'TestSMTP.sopm' );

{
    my $exec_output = capture_stdout {
        OPM::Maker::Command::filetest::execute( undef, {}, [ $sopm ] );
    };

    diag $exec_output;

    is $exec_output, '';
}

done_testing();
