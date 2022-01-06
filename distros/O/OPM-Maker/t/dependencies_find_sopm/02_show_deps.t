#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::dependencies';

my $dir       = File::Spec->rel2abs( dirname __FILE__ );
my $files_dir = File::Spec->catdir( $dir, '..', 'valid', 'deps' );

chdir $files_dir;

my $output = q~TestPackage - 1.0 (OPM package)
SMS::Send - 0.35 (CPAN module)
~;

{
    my $exec_output = capture_stdout {
        OPM::Maker::Command::dependencies::execute( undef, {}, [  ] );
    };

    is_string $exec_output, $output;
}

done_testing();
