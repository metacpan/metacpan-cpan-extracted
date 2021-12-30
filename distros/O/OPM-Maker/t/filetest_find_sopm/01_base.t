#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Spec;
use File::Basename;

use_ok 'OPM::Maker::Command::filetest';

my $dir         = File::Spec->rel2abs( dirname __FILE__ );
my $dir_to_test = File::Spec->catfile( $dir, '..', 'valid', 'TestSMTP');

chdir $dir_to_test;

my $args = [];
OPM::Maker::Command::filetest::execute( undef, {}, $args );

done_testing();
