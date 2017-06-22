use strict;
use warnings;

use lib::abs qw( ../lib .. );

use Test::More;

use Plack::Request;
use Plack::Session;
use Plack::Session::State;
use Plack::Session::Store::RedisFast;

use t::lib::TestSession;

t::lib::TestSession::run_all_tests(
    store  => Plack::Session::Store::RedisFast->new,
    state  => Plack::Session::State->new,
    env_cb => sub {
        open my $in, '<', \do { my $d };
        my $env = {
            'psgi.version'    => [ 1, 0 ],
            'psgi.input'      => $in,
            'psgi.errors'     => *STDERR,
            'psgi.url_scheme' => 'http',
            SERVER_PORT       => 80,
            REQUEST_METHOD    => 'GET',
            QUERY_STRING => join "&" => map { $_ . "=" . $_[0]->{$_} }
              keys %{ $_[0] || +{} },
        };
    },
);

done_testing;
