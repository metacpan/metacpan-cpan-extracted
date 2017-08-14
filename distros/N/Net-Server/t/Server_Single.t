#!/usr/bin/env perl

use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag);
prepare_test({n_tests => 1, plan_only => 1});

use_ok('Net::Server::Single');

### not much to test
### this is only a personality for the MultiType
