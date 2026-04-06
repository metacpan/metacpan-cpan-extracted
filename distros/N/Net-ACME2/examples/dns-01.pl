#!/usr/bin/env perl

package examples::dns_01;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent (
    'Net_ACME2_Example_DNS01',
    'Net_ACME2_Example_Sync',
);

__PACKAGE__->run() if !caller;

1;
