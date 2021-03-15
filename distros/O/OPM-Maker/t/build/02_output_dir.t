#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::build';

my $dir    = File::Spec->rel2abs( dirname __FILE__ );
my $output = tempdir( CLEANUP => 1 );
my $sopm   = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP', 'TestSMTP.sopm' );
my $opm    = File::Spec->catfile( $output, 'TestSMTP-0.0.1.opm' );

OPM::Maker::Command::build::execute( undef, { output => $output }, [ $sopm ] );

ok -e $opm;
ok( unlink $opm );
ok !-e $opm;

done_testing();
