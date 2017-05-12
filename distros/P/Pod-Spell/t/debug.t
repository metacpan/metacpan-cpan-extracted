use strict;
use warnings;
use Test::More;
use Pod::Spell;

my $p0 = new_ok 'Pod::Spell' => [ debug => 0 ];
my $p1 = new_ok 'Pod::Spell' => [ debug => 1 ];

ok ! $p0->_is_debug, 'debug unset';
ok   $p1->_is_debug, 'debug set';

done_testing;
