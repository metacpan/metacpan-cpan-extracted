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
plan skip_all => 'deprecated';
unless ( $ENV{TEST_RPC_URL} ) {
    plan skip_all => "set TEST_RPC_URL for XML RPC SERVER";
}
else {
    plan tests => 11;
}
use_ok('Net::RTorrent');
my $rpc_url = $ENV{TEST_RPC_URL};
isa_ok my $obj = ( new Net::RTorrent:: $rpc_url ), 'Net::RTorrent',
  'create object';
isa_ok my $dloads = $obj->get_downloads, 'Net::RTorrent::Downloads',
  'check download object';
my $keys = $dloads->list_ids;
ok @$keys, 'get list of keys';
ok my $k1 = shift(@$keys), 'get first key';
ok my $k2 = shift(@$keys), 'get second key';
diag "$k1 \n$k2";

foreach my $dl (@$keys) {
    my $d = $dloads->fetch_one($dl);

    #    diag join " ",@{$d->attr}{qw /hash up_total base_filename/}

}

#test for upload
my $file = 't/setup_punto_switcher_30.exe.torrent';
my $data;
{
    local $/ = undef;
    open FH, $file;
    $data = <FH>;
    close FH;
};
diag length $data;
my $resp = $obj->load_raw( $data, 0 );
#diag Dumper $resp->value;

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

