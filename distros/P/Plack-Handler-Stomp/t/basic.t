#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
use Test::Plack::Handler::Stomp;

has t => (
    is => 'rw',
    default => sub { Test::Plack::Handler::Stomp->new() }
);

test 'instantiate the handler' => sub {
    my ($self) = @_;

    ok($self->t->handler,'built');
};

test 'connecting with defaults' => sub {
    my ($self) = @_;

    my $t=$self->t;

    $t->handler->run();

    is($t->constructor_calls_count,1,'built once');
    my $call = $t->constructor_calls->[0];
    cmp_deeply($call,
              {
                  hosts => [{
                      hostname => 'localhost',
                      port => 61613,
                  }],
                  logger => ignore(),
              },
              'default parameters');

    is($t->connection_calls_count,1,'connected once');
    $call = $t->connection_calls->[0];
    is_deeply($call,{},'no connection headers');
};

run_me;
done_testing;
