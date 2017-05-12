use lib 't/lib';
use Test::More;
use Test::Riak;

test_riak_rest {
    my ($client) = @_;
    my $resp = $client->stats;
    is ref($resp), 'HASH', 'got stats';
    ok exists $resp->{webmachine_version}, 'contains expected key';
};
