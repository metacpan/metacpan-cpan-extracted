#!/usr/bin/env perl

package examples::http_01;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent (
    'Net_ACME2_Example_Sync',
    'Net_ACME2_Example_HTTP01',
);

__PACKAGE__->run() if !caller;

1;
