#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OTRS::OPM::Maker::Command::build';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $sopm = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP', 'TestSMTP.sopm' );
my $opm  = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP', 'TestSMTP-0.0.1.opm' );

OTRS::OPM::Maker::Command::build::execute( undef, {}, [ $sopm ] );

ok -e $opm;
ok( unlink $opm );
ok !-e $opm;

done_testing();
