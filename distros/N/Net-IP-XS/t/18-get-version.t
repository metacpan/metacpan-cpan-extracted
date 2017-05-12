#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 4;

use Net::IP::XS qw(ip_get_version);

my $res = ip_get_version('127.0.0.1');
is($res, 4, 'ip_get_version 4');

$res = ip_get_version('::');
is($res, 6, 'ip_get_version 6 1');

$res = ip_get_version('2000::');
is($res, 6, 'ip_get_version 6 2');

$res = ip_get_version('2000::.asdf');
is($res, undef, 'ip_get_version invalid');

1;
