#!perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'author tests run only if $ENV{CLOUDSERVERS_AUTHOR_TESTS} set'
    if (!defined $ENV{'CLOUDSERVERS_AUTHOR_TESTS'}
    || !$ENV{'CLOUDSERVERS_AUTHOR_TESTS'});
plan skip_all => 'author tests need $ENV{CLOUDSERVERS_USER} set'
    if (!defined $ENV{'CLOUDSERVERS_USER'});
plan skip_all => 'author tests need $ENV{CLOUDSERVERS_KEY} set'
    if (!defined $ENV{'CLOUDSERVERS_KEY'});

use Net::RackSpace::CloudServers;
plan 'no_plan';

#$Net::RackSpace::CloudServers::DEBUG = 1;
my $CS;
eval {
    $CS = Net::RackSpace::CloudServers->new(
        user => $ENV{'CLOUDSERVERS_USER'},
        key  => $ENV{'CLOUDSERVERS_KEY'},
    );
};
ok(!$@,         'Object created ok');
ok(defined $CS, 'Connected ok');

my @current_servers = $CS->get_server_detail;
ok(@current_servers, 'Got list of servers');

#author test: have one server only (test00) - TODO: update #tests
SKIP: {
    skip 'more than one server found, author has only one', 9
        if (scalar @current_servers != 1);
    note 'Server id: ',     $current_servers[0]->id;
    note 'Server hostid: ', $current_servers[0]->hostid;
    note 'Server name: ',   $current_servers[0]->name;
    is $current_servers[0]->name, 'test00', 'server name is test00';
    note 'Server flavorid: ', $current_servers[0]->flavorid;
    is $current_servers[0]->flavorid, 1, 'test00 flavorid is 1';
    note 'Server imageid: ', $current_servers[0]->imageid;
    is $current_servers[0]->imageid, 8, 'test00 imageid is 8';
    note 'Server status: ', $current_servers[0]->status;
    note 'Public address: ',
        join(' ', @{ $current_servers[0]->public_address || () });
    ok(defined $current_servers[0]->public_address,
        'has defined public address');
    is @{ $current_servers[0]->public_address }, 1,
        'has 1 defined public address';
    ok($current_servers[0]->public_address->[0] =~ /^98\.129\.236/,
        'has right public address');
    note 'Private address: ',
        join(' ', @{ $current_servers[0]->private_address || () });
    ok(defined $current_servers[0]->private_address,
        'has defined private address');
    is @{ $current_servers[0]->private_address }, 1,
        'has 1 defined private address';
    ok($current_servers[0]->private_address->[0] =~ /^10\.176\.135/,
        'has right private address');
}
