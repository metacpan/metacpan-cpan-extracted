#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 17;

my $module = 'SVG::Calendar';

use_ok($module);

my $cal = SVG::Calendar->new();

# testing get_page
$cal->{page} = 'A4';
$cal->{width} = '';
$cal->{height} = '';
my %size = $cal->get_page();
ok( $cal->{page}{width} == 210, ' A4 page width = 210' );
is( $cal->{page}{width_unit}, 'mm', ' Default width units are mm' );
ok( $cal->{page}{height} == 297, ' A4 page height = 297' );
is( $cal->{page}{height_unit}, 'mm', ' Default height units are mm' );

$cal->{page} = 'A3';
$cal->{width} = '';
$cal->{height} = '';
%size = $cal->get_page();
ok( $cal->{page}{width} == 297, ' A3 page width = 297' );
is( $cal->{page}{width_unit}, 'mm', ' Default width units are mm' );
ok( $cal->{page}{height} == 420, ' A3 page height = 420' );
is( $cal->{page}{height_unit}, 'mm', ' Default height units are mm' );

$cal->{page} = { width => '1234', height => '5678' };
%size = $cal->get_page();
ok( $cal->{page}{width} == 1234, ' A3 page width('.$cal->{width}.') = 1234' );
is( $cal->{page}{width_unit}, 'px', ' Default width units are px' );
ok( $cal->{page}{height} == 5678, ' A3 page height('.$cal->{height}.') = 5678' );
is( $cal->{page}{height_unit}, 'px', ' Default height units are px' );

$cal->{page} = { width => '1234cm', height => '5678in' };
%size = $cal->get_page();
ok( $cal->{page}{width} == 1234, ' A3 page width('.$cal->{width}.') = 1234' );
is( $cal->{page}{width_unit}, 'cm', ' width units are cm' );
ok( $cal->{page}{height} == 5678, ' A3 page height('.$cal->{height}.') = 5678' );
is( $cal->{page}{height_unit}, 'in', ' height units are in' );
