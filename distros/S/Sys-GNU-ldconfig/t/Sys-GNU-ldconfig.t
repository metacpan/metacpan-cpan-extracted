#!/usr/bin/perl

use Test::More tests => 9;
BEGIN { 
    use_ok('Sys::GNU::ldconfig') 
};

use Config;
use FindBin;
use File::Spec;
my $tdir = $FindBin::Bin;

my $so = $Config{dlext};
my $so3 = ".$so";
my $so4 = ".$so";
my $so13 = ".$so";
if( $^O eq 'Win32' ) {
    $so3 = "3.$so";
    $so4 = "4.$so";
    $so13 = "13.$so";
}
else {
    $so3 .= ".3";
    $so4 .= ".4";
    $so13 .= ".13";
}

#### functional interface
ld_root( File::Spec->catdir( $tdir ) );
my $file = ld_lookup( "db" );
is( $file, File::Spec->catfile( '', "lib", "libdb$so4" ), "found db" );

#### OO interface
my $ld = Sys::GNU::ldconfig->new;
isa_ok( $ld, 'Sys::GNU::ldconfig' );
$ld->root( File::Spec->catdir( $tdir ) );

$file = $ld->lookup( "db" );
is( $file, File::Spec->catfile( '', "lib", "libdb$so4" ), "found db via OO" );

$file = $ld->lookup( "libdb" );
is( $file, File::Spec->catfile( '', "lib", "libdb$so4" ), "found db via OO" );

$file = $ld->lookup( "db$so3" );
is( $file, File::Spec->catfile( '', "old-lib", "libdb$so3" ), "found older db via OO" );

$file = $ld->lookup( "something" );
is( $file, File::Spec->catfile( '', qw( opt something-1.23 lib ), "libsomething.$so" ), 
                                    "found something in opt" );

$file = $ld->lookup( "other" );
is( $file, File::Spec->catfile( '', qw( opt lib ), "libother$so13" ),
                                    "found something in opt" );

$file = $ld->lookup( "libother.$so" );
is( $file, File::Spec->catfile( '', qw( opt lib ), "libother$so13" ),
                                    "found something in opt" );

