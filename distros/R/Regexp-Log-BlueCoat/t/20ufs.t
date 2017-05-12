use Test::More tests => 7;
use strict;
use Regexp::Log::BlueCoat;

my ( $log, $regexp );

# default value
is( $Regexp::Log::BlueCoat::UFS{smartfilter}{hm},
    'humor', "Default for category" );

$log = Regexp::Log::BlueCoat->new( ufs => 'smartfilter', format => '%f' );

# GET methods
my %ufs_i = $log->ufs_category;
my %ufs_c = Regexp::Log::BlueCoat->ufs_category('smartfilter');
is_deeply( \%ufs_i, \%ufs_c, "Instance UFS equals class UFS" );

# SET methods
# instance method
$log->ufs_category( hm => 'Fun' );
$regexp = $log->regexp;

%ufs_i = $log->ufs_category;
%ufs_c = Regexp::Log::BlueCoat->ufs_category('smartfilter');
like( $regexp, qr/\bFun\b/, "ufs_category on instance" );
is( $ufs_i{hm}, 'Fun',   "Instance data changed" );
is( $ufs_c{hm}, 'humor', "Class data not changed" );

# class method
undef $log;
Regexp::Log::BlueCoat->ufs_category( 'smartfilter', js => 'Work' );

$log    = Regexp::Log::BlueCoat->new( ufs => 'smartfilter', format => '%f' );
$regexp = $log->regexp;

like( $regexp, qr/\bWork\b/, "ufs_category from class" );
is( $Regexp::Log::BlueCoat::UFS{smartfilter}{js}, 'Work',
    "Class data changed" );

