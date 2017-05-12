BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use strict;
use warnings;
use Test::More tests => 2;
use Riak::Light;

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

my $client = Riak::Light->new(
    host             => $host, port => $port,
    timeout_provider => undef
);

is $client->set_client_id('ID'), 1, 'can set';

is $client->get_client_id, 'ID', 'should return the client id';
