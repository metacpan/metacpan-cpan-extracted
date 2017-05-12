#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 18;

my $module = 'SVG::Calendar';

use_ok($module);

my $cal = SVG::Calendar->new( INCLUDE_PATH => 'templates' );

isa_ok( $cal, $module );

can_ok( $cal, 'output' );

ok( $cal->output(), 'Try to generate output' );
ok( $cal->output_month('2008-10'), 'Try to generate output for a month' );

my @months = $cal->output_year('2008', 'test');
ok( @months == 12, 'Try to generate output for a year' );

for my $file (@months) {
    ok( -s $file, 'The month calandar has some size' );
    # clean up
    unlink $file;
}
