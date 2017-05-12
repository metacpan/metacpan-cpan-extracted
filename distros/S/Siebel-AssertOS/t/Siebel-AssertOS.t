use strict;
use warnings;
use Test::More tests => 1;

# must use the module to check other things
eval 'use Siebel::AssertOS';
can_ok( 'Siebel::AssertOS', qw(die_if_os_isnt die_unsupported os_is) );

