#!perl -Tw

use strict;

use Test::More tests => 4;

use PICA::Field;

my ($occ, $tag);
($occ, $tag) = parse_pp_tag('021A');
ok( $tag eq '021A', 'parse_pp_tag' );
ok( parse_pp_tag('021A'), 'parse_pp_tag' );

($occ, $tag) = parse_pp_tag('009X/01');
ok( ($occ eq '01') && ($tag eq '009X'), 'parse_pp_tag');

ok( !parse_pp_tag('009_') , 'parse_pp_tag');
