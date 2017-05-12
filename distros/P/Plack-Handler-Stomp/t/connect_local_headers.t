#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
use Test::Plack::Handler::Stomp;

test 'connecting with supplied params' => sub {
    my ($self) = @_;

    my $t = Test::Plack::Handler::Stomp->new();

    my $conn_head = {
        login => 'myuser',
        password => 'mypass',
    };
    my $new_params = {
        hostname => 'foo',
        port => 12345,
        connect_headers => $conn_head,
    };

    $t->set_arg(
        servers => [$new_params],
    );

    $t->handler->run();

    is($t->constructor_calls_count,1,'built once');
    my $call = $t->constructor_calls->[0];
    cmp_deeply($call,{hosts=>[$new_params],logger=>ignore()},'custom host used');

    is($t->connection_calls_count,1,'connected once');
    $call = $t->connection_calls->[0];
    cmp_deeply($call,$conn_head,'custom connect headers used');
};

run_me;
done_testing;
