#!perl -T

use strict;
use warnings;
use Test::More tests => 10;
use Test::File;

use File::Spec;
use Cwd;

use lib 'blib/lib';

use FindBin qw($Bin);

my $testpath = File::Spec->catfile( 'a', 'b' );

(my $separator) = ($testpath =~ m:^a(.)b$:);

( my( $test_dir, $dist_dir ) ) = ( $Bin =~ m:^((.*?)${separator}t)$: );

ok( -d $dist_dir, '$dist_dir is a directory' );
ok( -d $test_dir, '$test_dir is a directory' );

my $data_dir = File::Spec->catfile( $test_dir, 'data' );

ok( -d $data_dir, '$data_dir is a directory' );

my $convert_script
    = File::Spec->catfile( $dist_dir, 'blib', 'script', 'convert-nvdcve' );

ok( -f $convert_script, '$convert_script is a file' );

(my $source_file) = ( File::Spec->catfile( $data_dir, 'nvdcve-2.0-test.xml' )
        =~ m:^(.*?.nvdcve-2.0-test.xml)$: );

ok( -f $source_file, '$source_file is a file' ) or diag $source_file;

my $db_file = File::Spec->catfile( $data_dir, 'nvdcve-2.0.db' );

unlink($db_file) if -f $db_file;

ok( !-e $db_file, '$db_file does not yet exist' );

my $cpe_idx_file = File::Spec->catfile( $data_dir, 'nvdcve-2.0.idx_cpe.db' );

unlink($cpe_idx_file) if -f $cpe_idx_file;

ok( !-e $cpe_idx_file, '$cpe_idx_file does not yet exist' );

undef $ENV{PATH};
undef $ENV{ENV};
undef $ENV{CDPATH};

$ENV{PERL5LIB} = File::Spec->catfile( $dist_dir, 'blib', 'lib' );

chdir($data_dir);

my $output = `$convert_script $source_file 2>&1`;

is( $?, 0, 'conversion script returned cleanly' ) or diag $output;
file_exists_ok( $db_file,      'database file exists' );
file_exists_ok( $cpe_idx_file, 'CPE index database file exists' );

chdir($test_dir);

