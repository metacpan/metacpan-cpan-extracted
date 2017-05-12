use strict;
use warnings;
use Test::More;
use Test::TCP;

eval q{use AnyEvent::MPRPC::Server; 1};
if ($@) {
    plan skip_all
        => "AnyEvent::MPRPC is required to run this test";
}

use Net::MPRPC::Client;

test_tcp(
    server => sub {
        my $port = shift;
        my $w = AnyEvent->signal( signal => 'PIPE', cb => sub { warn "SIGPIPE" } );

        my $server = AnyEvent::MPRPC::Server->new(host => '127.0.0.1', port => $port);
        $server->reg_cb(
            sum => sub {
                my ($res_cv, $args) = @_;
                my $i = 0;
                $i += $_ for @$args;
                $res_cv->result( $i );
            },
        );
        AnyEvent->condvar->recv;
    },
    client => sub {
        my $port = shift;
        my $client = Net::MPRPC::Client->new(
            host => '127.0.0.1',
            port => $port,
        );

        my $res = $client->call( sum => [qw/1 2 3/] );
        is $res, 6;
        done_testing;
    },
);
