use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'NetAddr::MAC' ) or BAIL_OUT('unable to load module') }

diag( "Testing NetAddr::MAC $NetAddr::MAC::VERSION, Perl $], $^X" );
