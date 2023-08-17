#!perl -w
use strict;
use warnings;

use Config;
use Test::More;
use Test::Compile qw( pl_file_ok );

if ( $Config{taint_disabled} ) {
    plan skip_all => "This perl was compiled without taint support";
}

pl_file_ok('t/scripts/taint.pl', 'taint.pl compiles');
done_testing();
