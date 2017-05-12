#!perl -T
use warnings;
use strict;

use Test::More tests => 3;
use Normalize;

#test1
my $norm = Normalize->new();
ok( $norm && ref($norm) eq 'Normalize',  'new() works' );
ok( $norm->get('round_to') && $norm->get('round_to') == 0.01,  'defaults values' );
ok( $norm->set('round_to', 0.1) && $norm->get('round_to') == 0.1,  'set object data values' );



#min_default