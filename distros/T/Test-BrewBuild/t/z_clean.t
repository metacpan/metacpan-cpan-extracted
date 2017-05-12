#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

unlink glob "*.bblog";

is (1, 1, "ok");

done_testing();
