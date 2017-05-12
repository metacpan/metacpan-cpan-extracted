use strict;
use warnings;

use Data::Printer;
use File::Temp qw( tempfile );
use Module::Version::Loaded qw(
    diff_versioned_modules
    store_versioned_modules
    versioned_inc
    versioned_modules
);
use Test::More;

my %inc     = versioned_inc();
my %modules = versioned_modules();

ok( %inc, 'got versioned inc' );
cmp_ok(
    $inc{'Module/Version.pm'}, '>=', 0.12,
    'Module::Version gets its own version in inc'
);

cmp_ok(
    $modules{'Module::Version'}, '>=', 0.12,
    'Module::Version gets its own version in modules'
);

diag p %inc;
diag p %modules;

# just make sure the following don't throw an exception
my ( $fh_before, $filename_before ) = tempfile();

store_versioned_modules($filename_before);

my ( $fh_after, $filename_after ) = tempfile();

require Path::Tiny;
store_versioned_modules($filename_after);

if ( $ENV{MVL_DEBUG} ) {
    diff_versioned_modules( $filename_before, $filename_after );
}

done_testing();
