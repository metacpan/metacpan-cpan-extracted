#!/usr/bin/env perl -T
use Carp::Always;
use List::Util qw(any);
use LWP::Online qw(:skip_all);
use Test::More;
use strict;

my $base = q{Net::RDAP};

require_ok $base;

my $class = $base.'::Service';

require_ok $class;

my $server = $class->new('https://rdap.db.ripe.net/');

isa_ok($server, $class);

ok($server->implements(q{rirSearch1}), q{server implements the RIR reverse search extension});

#
# TODO: add more tests
#

done_testing;
