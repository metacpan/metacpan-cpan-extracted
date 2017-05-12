# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MetaStore.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#env TEST_RPC_URL=http://10.100.0.1:8080/scgitest perl t/
use Test::More;
use Data::Dumper;
use strict;
use warnings;
use RPC::XML;
unless ( $ENV{TEST_RPC_URL} ) {
    plan skip_all => "set TEST_RPC_URL for XML RPC SERVER";
}
else {
    plan tests => 9;
}
use_ok('Net::RTorrent');
my $rpc_url = $ENV{TEST_RPC_URL};
isa_ok my $obj = ( new Net::RTorrent:: $rpc_url ), 'Net::RTorrent',
  'create object';
isa_ok my $dloads = $obj->get_downloads, 'Net::RTorrent::Downloads',
  'check download object';
my $keys = $dloads->list_ids;
ok @$keys, 'get list of keys';
my @tmp_store = @$keys;
ok my $k1 = shift(@$keys), 'get first key';
ok my $k2 = shift(@$keys), 'get second key';
isa_ok $dloads->get_one($k1), 'Net::RTorrent::DItem' ,'get item1';
# get all items
my $res = $dloads->get(@tmp_store);
ok scalar( keys %$res) ==  scalar( @tmp_store), 'check counts ids and objects';
ok $dloads->get_one($k1), 'check id';

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

