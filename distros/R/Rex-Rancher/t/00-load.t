use strict;
use warnings;
use Test::More;

use_ok('Rex::Rancher');
use_ok('Rex::Rancher::Node');
use_ok('Rex::Rancher::Server');
use_ok('Rex::Rancher::Agent');
use_ok('Rex::Rancher::Cilium');
use_ok('Rex::Rancher::K8s');

done_testing;
