#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::dependencies';

my $base = File::Spec->rel2abs( dirname __FILE__ );
my $dir  = File::Spec->catfile( $base, '..', 'valid', 'TestSMTP' );
chdir $dir;

OPM::Maker::Command::dependencies::execute( undef, {}, [ ] );

done_testing();
