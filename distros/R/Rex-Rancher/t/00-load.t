use strict;
use warnings;
use Test::More;

use_ok('Rex::Rancher');
use_ok('Rex::Rancher::Node');
use_ok('Rex::Rancher::Server');
use_ok('Rex::Rancher::Agent');
use_ok('Rex::Rancher::Cilium');
use_ok('Rex::Rancher::K8s');
use_ok('Rex::Rancher::Distribution');
use_ok('Rex::Rancher::Options');
use_ok('Rex::Rancher::Checksum');
use_ok('Rex::Rancher::Uninstall');
use_ok('Rex::Rancher::Distribution::RKE2');
use_ok('Rex::Rancher::Distribution::K3s');

done_testing;
