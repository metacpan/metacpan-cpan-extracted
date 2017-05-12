#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 9;

use_ok( 'Spreadsheet::HTML' ) or BAIL_OUT( "can't use module" );
my $obj = new_ok( 'Spreadsheet::HTML' ) or BAIL_OUT( "can't instantiate object" );
for (qw( generate portrait landscape north south east west ) ) {
    can_ok( $obj, $_ ) or BAIL_OUT( "can't $_" );
}
