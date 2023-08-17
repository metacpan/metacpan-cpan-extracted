#!/usr/bin/perl

use Test::More tests => 10;
BEGIN { 
    use_ok('Sys::GNU::ldconfig') 
};

use strict;
use warnings;

use Config;
use FindBin;
use File::Spec;
my $tdir = $FindBin::Bin;

my $so = $Config{dlext};
my $soD;
if( $^O eq 'Win32' ) {
    $soD = "(\\.\\d+)?\\.$so";
}
else {
    $soD = "\\.$so(\\.\\d+)?";
}


my $not = ld_lookup( "nevermatch" );
is( $not, undef, "libnevermatch isn't installed" );

#### functional interface
ld_root( File::Spec->catdir( $tdir ) );
my $file = ld_lookup( "db" );
is_like( $file, File::Spec->catfile( '', "lib", "libdb$soD" ), "found db" );

#### OO interface
my $ld = Sys::GNU::ldconfig->new;
isa_ok( $ld, 'Sys::GNU::ldconfig' );
$ld->root( File::Spec->catdir( $tdir ) );

$file = $ld->lookup( "db" );
is_like( $file, File::Spec->catfile( '', "lib", "libdb$soD" ), "found db via OO" );

$file = $ld->lookup( "libdb" );
is_like( $file, File::Spec->catfile( '', "lib", "libdb$soD" ), "found db via OO" );

$file = $ld->lookup( "db.so.3" );
is_like( $file, File::Spec->catfile( '', "old-lib", "libdb$soD" ), "found older db via OO" );

$file = $ld->lookup( "something" );
is_like( $file, File::Spec->catfile( '', qw( opt something-1.23 lib ), "libsomething.$so" ), 
                                    "found something in opt" );

$file = $ld->lookup( "other" );
is_like( $file, File::Spec->catfile( '', qw( opt lib ), "libother$soD" ),
                                    "found something in opt" );

$file = $ld->lookup( "libother.$so" );
is_like( $file, File::Spec->catfile( '', qw( opt lib ), "libother$soD" ),
                                    "found something in opt" );

sub is_like
{
    my( $file, $re, $msg ) = @_;
    SKIP: {
        unless( $file ) {
            skip "libdb not installed", 1;
        }
        else {
            like( $file, qr/^$re$/, $msg );
        }
    }
}

