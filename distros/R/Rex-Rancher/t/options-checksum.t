use strict;
use warnings;
use Test::More;

# k57: the option checks and the checksum parsing moved out of
# Rex::Rancher::Distribution, which still answers them (its callers keep
# working). Both ways give the same results and the same dies. Pure: nothing
# here touches a host.

use Rex::Rancher::Checksum;
use Rex::Rancher::Distribution;
use Rex::Rancher::Options;

my $D = 'Rex::Rancher::Distribution';
my $H = 'a' x 64;

sub both {
  my ( $class, $method, @args ) = @_;
  my @r = map {
    my $inv = $_;
    my $r = eval { [ $inv->$method(@args) ] };
    $r // "died: $@";
  } $class, $D;
  is_deeply( $r[0], $r[1], "$method(" . join( ', ', map { $_ // 'undef' } @args ) . "): $class and $D agree" );
  return $r[0];
}

is_deeply( both( 'Rex::Rancher::Options', 'resolve_install_method' ), ['script'], 'script by default' );
is_deeply( both( 'Rex::Rancher::Options', 'resolve_install_method', 'artifact', 'v1' ), ['artifact'], 'artifact' );
like( both( 'Rex::Rancher::Options', 'resolve_install_method', 'artifact' ), qr/^died: install_method 'artifact' requires a version/, 'artifact without version' );
like( both( 'Rex::Rancher::Options', 'resolve_install_method', 'rpm' ), qr/^died: Unknown install_method: rpm/, 'unknown method' );

is_deeply( both( 'Rex::Rancher::Options', 'check_cluster_cidr', '10.9.0.0/16' ), ['10.9.0.0/16'], 'a CIDR' );
is_deeply( both( 'Rex::Rancher::Options', 'check_cluster_cidr', undef ), [], 'undef' );
like( both( 'Rex::Rancher::Options', 'check_cluster_cidr', $_ ), qr/^died: cluster_cidr must be one IPv4 CIDR/, "'$_' dies" )
  for '10.0.0.0', '256.0.0.0/8', '10.0.0.0/33', 'fd00::/64';

is_deeply( both( 'Rex::Rancher::Checksum', 'expected_sha256', "$H  k3s-airgap-images\n" . uc($H) . " *k3s\n", 'k3s' ), [$H],
  'exact asset name, lower-cased' );
is_deeply( both( 'Rex::Rancher::Checksum', 'expected_sha256', "$H  k3s-airgap\n", 'k3s' ), [], 'no match' );
is_deeply( both( 'Rex::Rancher::Checksum', 'sha256_of', "$H  /tmp/x\n" ), [$H], 'sha256sum output' );
is_deeply( both( 'Rex::Rancher::Checksum', 'verify_sha256', $H, $H, 'x' ), [1], 'equal' );
like( both( 'Rex::Rancher::Checksum', 'verify_sha256', $H, 'b' x 64, 'x' ), qr/^died: Checksum mismatch for x/, 'mismatch' );
like( both( 'Rex::Rancher::Checksum', 'verify_sha256', undef, $H, 'x' ), qr/^died: No checksum for x/, 'no expected' );

done_testing;
