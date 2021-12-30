#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::sopmtest';

my $dir  = File::Spec->rel2abs( dirname __FILE__ );
my $sopm = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP' );
chdir $sopm;

OPM::Maker::Command::sopmtest::execute( undef, {}, [  ] );

done_testing();
