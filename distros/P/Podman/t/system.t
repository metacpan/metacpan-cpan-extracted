## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();
use Mock::Podman::Service;

use Podman::System;

local $ENV{PODMAN_CONNECTION_URL} =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

my $service = Mock::Podman::Service->new();
my $system  = Podman::System->new();

$service->start;
my $expected_data = {
    "APIVersion" => "3.0.0",
    "Version"    => "3.0.1",
    "GoVersion"  => "go1.15.9",
    "BuiltTime"  => "Thu Jan  1 01:00:00 1970",
    "OsArch"     => "linux/amd64"
};
my $actual_data = $system->version;
is( ref $actual_data, 'HASH', 'Version ok.' );
is_deeply( $actual_data, $expected_data, 'Version response ok.' );

$expected_data = {
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
$actual_data = $system->disk_usage();
is( ref $actual_data, 'HASH', 'Disk usage ok.' );
is_deeply( $actual_data, $expected_data, 'Disk usage response ok.' );

$actual_data = $system->info();
is( ref $actual_data, 'HASH', 'Info ok.' );
my @expected_keys = qw(host registries store version);
my @actual_keys   = sort keys %{$actual_data};
is_deeply( \@actual_keys, \@expected_keys, 'Info response ok.' );

$service->stop;

done_testing();
