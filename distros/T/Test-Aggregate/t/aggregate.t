#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;

my $dump = 'dump.t';
my $tests = Test::Aggregate->new( { dirs => 'aggtests', } );
$tests->run;

#ok -f $dump, '... and we should have written out a dump file';
#unlink $dump or warn "Cannot unlink ($dump): $!";
