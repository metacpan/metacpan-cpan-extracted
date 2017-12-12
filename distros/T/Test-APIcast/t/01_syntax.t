#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

is(system("$^X -c -Ilib lib/Test/APIcast.pm"), 0, 'APIcast.pm syntax OK');
is(system("$^X -c -Ilib lib/Test/APIcast/Blackbox.pm"), 0, 'APIcast/Blackbox.pm syntax OK');

done_testing();
