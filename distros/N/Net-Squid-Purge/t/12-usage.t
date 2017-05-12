#!perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Group;
use Test::Exception;

use_ok 'Net::Squid::Purge';

my ($sp);

test 'object creation' => sub {
    $sp = Net::Squid::Purge->new(type => 'HTTP');
    ok($sp);
    isa_ok($sp, 'Net::Squid::Purge::HTTP');
};

test 'purge request creation' => sub {
    my @response = $sp->_format_purge('http://www.socklabs.com/');
    is($response[0], 'PURGE');
    is($response[1], 'http://www.socklabs.com/');
    is($response[2], 'Accept');
    is($response[3], '*/*');
};

test 'bad purge request creation' => sub {
    dies_ok { $sp->_format_purge(); } 'missing url';
    dies_ok { $sp->_format_purge(undef); } 'undef url';
};
