## no critic
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use Data::Printer;
use File::Temp ();

use Mock::Podman::Service;

use Podman::Client;
use Podman::System;

my $Connection =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

my $Service = Mock::Podman::Service->new( Listen => $Connection );
$Service->Start();

my $Client = Podman::Client->new( Connection => $Connection );
my $System = Podman::System->new( Client     => $Client );

my $ExpectedData = {
    "APIVersion" => "3.0.0",
    "Version"    => "3.0.1",
    "GoVersion"  => "go1.15.9",
    "BuiltTime"  => "Thu Jan  1 01:00:00 1970",
    "OsArch"     => "linux/amd64"
};
my $ActualData = $System->Version();
is( ref $ActualData, 'HASH', 'Version ok.' );
is_deeply( $ActualData, $ExpectedData, 'Version response ok.' );

$ExpectedData = {
    "Containers" => {
        "Active" => "0",
        "Size"   => "13256",
        "Total"  => "1"
    },
    "Images" => {
        "Active" => "2",
        "Size"   => "129100529",
        "Total"  => "2"
    },
    "Volumes" => {
        "Active" => "0",
        "Size"   => "0",
        "Total"  => "1"
    }
};
$ActualData = $System->DiskUsage();
is( ref $ActualData, 'HASH', 'DiskUsage ok.' );
is_deeply( $ActualData, $ExpectedData, 'Version response ok.' );

$Service->Stop();

done_testing();
