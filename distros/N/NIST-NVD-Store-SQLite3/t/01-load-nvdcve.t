#!perl -T

use strict;
use warnings;
use Test::More tests => 21;
use Test::File;
use File::MMagic;
use File::LibMagic;
use FindBin qw($Bin);

use File::Spec;
use Cwd;

use NIST::NVD::Query;

( my $dist_dir )
    = ( Cwd::realpath( File::Spec->catfile( $Bin, '..' ) )
        =~ m:^(.*NIST-NVD-Store-SQLite3)$: );

ok( -d $dist_dir, '$dist_dir is a directory' );

my $test_dir = File::Spec->catfile( $dist_dir, 't' );

ok( -d $test_dir, '$test_dir is a directory' );

my $data_dir = File::Spec->catfile( $test_dir, 'data' );

ok( -d $data_dir, '$data_dir is a directory' );

my $convert_script
    = File::Spec->catfile( $dist_dir, 'blib', 'script', 'convert-nvdcve' );

ok( -f $convert_script, '$convert_script is a file' );

my $nvd_source_file = File::Spec->catfile( $data_dir, 'nvdcve-2.0-test.xml' );
my $cwe_source_file = File::Spec->catfile( $data_dir, 'cwec_v2.1.xml' );

ok( -f $nvd_source_file, '$nvd_source_file is a file' );

my $db_file = File::Spec->catfile( $data_dir, 'nvdcve-2.0.db' );

unlink($db_file) if -f $db_file;

ok( !-e $db_file, '$db_file does not yet exist' );

undef $ENV{PATH};
undef $ENV{ENV};
undef $ENV{CDPATH};

unlink($db_file) if -f $db_file;

chdir($data_dir);

$ENV{PERL5LIB} = File::Spec->catfile( $dist_dir, 'blib', 'lib' );

my $cmd
    = "$convert_script --nvd $nvd_source_file --cwe $cwe_source_file --store SQLite3 2>&1";
diag "running $cmd";
my $start_run = time();
my $output    = `$cmd`;
my $end_run   = time();
my $duration  = $end_run - $start_run;

ok( $duration <= 60,
    'took less than 60 seconds to load CWE data: ' . $duration );

is( $?, 0, 'conversion script returned cleanly' ) or diag $output;
file_exists_ok( $db_file, 'database file exists' );
file_not_empty_ok( $db_file, 'database file not empty' );
file_readable_ok( $db_file, 'database file readable' );
file_writeable_ok( $db_file, 'database file writeable' );
file_not_executable_ok( $db_file, 'database file not executable' );

my $mm  = new File::MMagic;
my $res = $mm->checktype_filename($db_file);

my ( $type, $fh, $data ) = ('application/octet-stream');

is( $res, $type, "file is correct type: [$type]" ) or diag $res;

my ($dev,  $ino,   $mode,  $nlink, $uid,     $gid, $rdev,
    $size, $atime, $mtime, $ctime, $blksize, $blocks
) = stat($db_file);

like( $mtime, qr/^\d+$/, 'mtime is numeric' ) or diag "mtime: [$mtime]";

my $nowish = time();

ok( $nowish - $mtime <= 1, '$mtime is close' )
    or diag "off by " . $nowish - $mtime;

open( $fh, q{<}, $db_file )
    or die "couldn't open file '$db_file': $!";

ok( $fh, 'opened database file for reading' );

$type = $mm->checktype_filehandle($fh);
is( $type, 'application/octet-stream',
    "file contents indicate correct type: [$type]" );

$fh->read( $data, 0x8564 );

$res = $mm->checktype_contents($data);

is( $type, 'application/octet-stream',
    "file contents indicate correct type: [$type]" );

my $flm = File::LibMagic->new();

$type = $flm->describe_filename($db_file);
is( $type,
    'SQLite 3.x database',
    "file contents indicate correct type: [$type]"
);

my $q;

$ENV{PERL5LIB} = File::Spec->catfile( $dist_dir, 'blib', 'lib' );

$q = NIST::NVD::Query->new( store => 'SQLite3', database => $db_file, );

is( ref $q, 'NIST::NVD::Query',
    'constructor returned an object of correct class' );

chdir($test_dir);

