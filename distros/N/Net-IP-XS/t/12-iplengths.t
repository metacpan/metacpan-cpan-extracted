#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 4;

use Net::IP::XS qw(ip_iplengths);
use IO::Capture::Stderr;

my $len = ip_iplengths(4);
is($len, 32, 'ip_iplengths 4');

$len = ip_iplengths(6);
is($len, 128, 'ip_iplengths 6');

$len = ip_iplengths(8);
is($len, undef, 'ip_iplengths invalid');

my $c = IO::Capture::Stderr->new();
$c->start();
$len = ip_iplengths(undef);
is($len, undef, 'ip_iplengths invalid');

1;
