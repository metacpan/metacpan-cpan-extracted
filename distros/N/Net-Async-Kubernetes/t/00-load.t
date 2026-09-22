use strict;
use warnings;
use Test::More tests => 4;

use_ok('Net::Async::Kubernetes');
use_ok('Net::Async::Kubernetes::Watcher');
use_ok('Net::Async::Kubernetes::Controller');
use_ok('Net::Async::Kubernetes::PortForwardSession');
