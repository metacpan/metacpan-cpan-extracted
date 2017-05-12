#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

    pass("Preload ObjectDB\n".'*' x 10);
SKIP: {
    eval {require ObjectDB};
    skip "ObjectDB not installed", 'no_plan' if $@;
    
    pass("Check interface\n".'*' x 10);
    ok(ObjectDB->can('inflate_column') ? 0 : 1, 'ObjectDB::inflate_column is clear');
    ok(ObjectDB::Schema->can('inflate_column') ? 0 : 1, 'ObjectDB::Schema::inflate_column is clear');
    ok(ObjectDB::Schema->can('_inflate_columns_info') ? 0 : 1, 'ObjectDB::Schema::_inflate_columns_info is clear');
    
    pass("Try load ObjectDB::InflateColumn\n".'*' x 10);
    use_ok('ObjectDB::InflateColumn');
    
    pass("Check new interface\n".'*' x 10);
    can_ok('ObjectDB::Schema', 'inflate_column');
    can_ok('ObjectDB::Schema', '_inflate_columns_info');
    can_ok('ObjectDB', 'inflate_column');
    
    
            
}        

    pass("end\n".'*' x 10);
    done_testing();
