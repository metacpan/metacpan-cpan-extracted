use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak_pbc {
    my ($client) = @_;
    my $resp = $client->server_info;
    ok exists $resp->{node}, 'got server node';
    ok exists $resp->{server_version}, 'got server version';
};
