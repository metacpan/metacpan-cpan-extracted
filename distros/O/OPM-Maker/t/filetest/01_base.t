#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::filetest';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $sopm = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP', 'TestSMTP.sopm' );
my $opm  = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP', 'TestSMTP-0.0.1.opm' );

OPM::Maker::Command::filetest::execute( undef, {}, [ $sopm ] );

done_testing();
