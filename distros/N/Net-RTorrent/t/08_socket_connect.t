
#env TEST_RPC_ADDR=10.100.0.1:5000 perl t/
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use RPC::XML;
unless ( $ENV{TEST_RPC_ADDR} ) {
     plan tests => 5;
}
else {
    plan tests => 8;
}
use_ok('Net::RTorrent');
use_ok('Net::RTorrent::Socket');

my $bad = new Net::RTorrent::Socket::;
ok !$bad, 'empty params';
my $scli1 = new Net::RTorrent::Socket:: 'localhost:5000';
isa_ok $scli1, 'Net::RTorrent::Socket', 'create instance';

my $scli2 = new Net::RTorrent::Socket:: '/tmp/torrent.sock';
isa_ok $scli2, 'Net::RTorrent::Socket', 'create instance';

if ( my $rpc_addr = $ENV{TEST_RPC_ADDR} ) {

    #test for conect
    my $scli3 = new Net::RTorrent::Socket:: $rpc_addr;
    isa_ok $scli3, 'Net::RTorrent::Socket', 'create instance';
    my $req = RPC::XML::request->new('get_memory_usage');
    my $res = $scli3->send_request($req);
    isa_ok $res, 'RPC::XML::i4';
    ok $res->value, 'get test value';
}

