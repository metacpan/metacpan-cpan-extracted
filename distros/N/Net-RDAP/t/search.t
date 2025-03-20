#!/usr/bin/env perl
use LWP::Online qw(:skip_all);
use List::Util qw(any);
use Test::More;
use URI;
use strict;

my $base = q{Net::RDAP};

require_ok $base;

my $class = $base.'::Service';

my $server = $class->new('https://rdap.verisign.com/net/v1');

isa_ok($server, $class);

my $result = $server->nameservers(
    ip => '198.41.0.4' # a.gtld-servers.net
);

isa_ok($result, $base.'::SearchResult');

my @objects = $result->nameservers;
cmp_ok(scalar(@objects), '>=', 0);

foreach my $object (@objects) {
    isa_ok($object, $base.'::Object::Nameserver');
}

$server = $class->new_for_tld(q{foo});

isa_ok($server, $class);

$result = $server->domains(name => q{nic.*});

isa_ok($result, $base.'::SearchResult');

my @objects = $result->domains;
cmp_ok(scalar(@objects), '>=', 0);

foreach my $object (@objects) {
    isa_ok($object, $base.'::Object::Domain');
}

done_testing;
