#!/usr/bin/perl
use List::Util qw(any);
use LWP::Online qw(:skip_all);
use Test::More;
use URI;
use strict;

my $base = q{Net::RDAP};

require_ok $base;

my $class = $base.'::Service';

my $server = $class->new('https://rdap.verisign.com/net/v1');

isa_ok($server, $class);

my $result = $server->implements('rdap_level_0');

done_testing;
