#!/usr/bin/env perl
use strict;
use Test::More 0.98;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok $_ for qw(
    MouseX::OO_Modulino
);

done_testing;

