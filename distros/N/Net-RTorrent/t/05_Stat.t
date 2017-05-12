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
    plan tests => 5;
}
use_ok('Net::RTorrent');
my $rpc_url = $ENV{TEST_RPC_URL};
isa_ok my $obj = ( new Net::RTorrent:: $rpc_url ), 'Net::RTorrent',
  'create object';
isa_ok my $cli = $obj->_cli, 'RPC::XML::Client', 'test cli attr';
ok my $sys_stat  =  $obj->system_stat ,'get system_stat';
ok $sys_stat->{pid}, 'check system.pid';
#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

