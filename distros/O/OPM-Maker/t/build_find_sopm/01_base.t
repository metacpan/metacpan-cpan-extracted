#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::build';

my $base = File::Spec->rel2abs( dirname __FILE__ );
my $dir  = File::Spec->catdir( $base, qw/.. valid TestSMTP/ );
my $opm  = File::Spec->catfile( $dir, 'TestSMTP-0.0.1.opm' );

chdir $dir;

OPM::Maker::Command::build::execute( undef, {}, [ ] );

ok -e $opm;
ok( unlink $opm );
ok !-e $opm;

done_testing();
