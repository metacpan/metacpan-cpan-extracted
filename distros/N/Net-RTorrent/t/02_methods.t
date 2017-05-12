# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MetaStore.t'

#########################
#$Id: 02_methods.t 641 2009-11-14 12:49:02Z zag $

# change 'tests => 1' to 'tests => last_test_to_print';
#env TEST_RPC_URL=http://10.100.0.1:8080/scgitest perl t/
#env TEST_RPC_ADDR=10.100.0.1:5000 perl t/

use Test::More;
use Data::Dumper;
my $addr = $ENV{TEST_RPC_URL} || $ENV{TEST_RPC_ADDR};
unless ( $addr ) {
    plan skip_all => "set TEST_RPC_URL || TEST_RPC_ADDR for XML RPC SERVER";
}
else {
    plan tests => 7;
}
use_ok('Net::RTorrent');
isa_ok   my $obj = (new Net::RTorrent:: $addr ), 'Net::RTorrent', 'create object';
my $keys = $obj->list_ids();
ok @$keys, 'get default list';
ok my $id1 = $keys->[0], 'get first key';
ok my $cli = $obj->_cli, 'get cli';
ok my $d1 = $obj->get_downloads('default'), 'get default';
ok scalar ( keys %{ $d1->fetch() }), 'not null';


