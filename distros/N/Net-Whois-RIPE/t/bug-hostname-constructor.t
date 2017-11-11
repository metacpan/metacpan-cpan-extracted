#!perl
use strict;
use warnings;
use Test::More tests => 2;

use Net::Whois::Generic;
use Iterator;

my $w = Net::Whois::Generic->new('hostname' => 'whois.radb.net');

my ($as_found) = $w->query('-T aut-num AS11344',
                               { type => 'AutNum' });

ok($as_found);
use Data::Dumper;
is($as_found->as_name(), 'METAWEB');
