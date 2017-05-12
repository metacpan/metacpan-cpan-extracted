#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use Perinci::Object;

my $riresmeta = riresmeta { };

is($riresmeta->type, "resmeta", "type");

done_testing();
