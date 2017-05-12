#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Maker::Command::sopmtest;

use File::Basename;
use File::Spec;

my $sopm = File::Spec->catfile( dirname( __FILE__ ), 'valid', 'TestSMTP', 'TestSMTP.sopm' );

my $success = OTRS::OPM::Maker::Command::sopmtest->execute( {}, [ $sopm ] );

ok $success;

done_testing();
