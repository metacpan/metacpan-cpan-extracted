#!env perl

use strict;use warnings;
use Data::Dumper;

use lib '../lib';
use Test::More;

use_ok('Net::DNS::Async::Simple');


my $list = [
    {   query => ['www.realms.org','A'],
    },{ query => ['174.136.1.7','PTR'],
        nameServers => ['8.8.4.4','4.2.2.2']
    }
];
Net::DNS::Async::Simple::massDNSLookup($list);
is($list->[0]->{address},'174.136.1.7', 'forward lookup worked');
is($list->[1]->{ptrdname},'tendotfour.realms.org', 'reverse lookup worked');

done_testing();
