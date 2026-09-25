use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit test for the openSUSE Leap NVIDIA repo/meta-package selection.
#
# Regression guard for karr #6: Rex::Commands::Gather::operating_system_version()
# strips dots ("15.6" -> "156"), so int() produced major 156 and *every* Leap
# fell into the ">= 16" branch — Leap 15.6 wrongly got the leap/16.0/ repo and
# the G07 meta package (the correct leap/15.x/ + G06 branch was unreachable).
# The major must be derived from the raw operating_system_release() string.
#
# The selection lives in Rex::GPU::NVIDIA::Setup::SUSE->sources (karr #33; it
# was _suse_nvidia_repo_params before). With the release injected into new()
# it reads nothing from the host, so it is unit-testable offline. The first
# source is the one a GPU without constraints (and no GPU) gets. The zypper
# I/O is NOT exercised here -- see the t/10-detect.t header: install_driver on
# a real distro node is a maintainer step, a green prove is not evidence it
# works.
# -----------------------------------------------------------------------------

use Rex::GPU::NVIDIA;

sub params {
  my ( $release ) = @_;
  my ( $first ) = Rex::GPU::NVIDIA::Setup::SUSE->new(release => $release)->sources;
  return ( $first->{repo_url}, $first->{packages}[0] );
}

subtest 'Leap 15.6 => leap/15.6 repo + G06 meta' => sub {
  my ($repo, $meta) = params('15.6');
  is($repo, 'https://download.nvidia.com/opensuse/leap/15.6/',
    'repo URL keeps the 15.6 minor');
  is($meta, 'nvidia-open-driver-G06-signed-kmp-meta', 'meta package is G06 (Leap 15.x)');
};

subtest 'Leap 15.5 => leap/15.5 repo + G06 meta' => sub {
  my ($repo, $meta) = params('15.5');
  is($repo, 'https://download.nvidia.com/opensuse/leap/15.5/',
    'repo URL keeps the 15.5 minor');
  is($meta, 'nvidia-open-driver-G06-signed-kmp-meta', 'meta package is G06 (Leap 15.x)');
};

subtest 'Leap 16.0 => leap/16.0 repo + G07 meta' => sub {
  my ($repo, $meta) = params('16.0');
  is($repo, 'https://download.nvidia.com/opensuse/leap/16.0/', 'repo URL is leap/16.0');
  is($meta, 'nvidia-open-driver-G07-signed-kmp-meta', 'meta package is G07 (Leap 16.x)');
};

done_testing;
