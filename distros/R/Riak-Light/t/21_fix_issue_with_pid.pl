#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::More tests => 1;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Test::TCP;

subtest "should reconnect if PID changes in case of real fork" => sub {
    plan tests => 2;

    my $server = Test::TCP->new(
        code => sub {
            my $port   = shift;
            my $socket = IO::Socket::INET->new(
                Listen    => 5,
                Timeout   => 1,
                Reuse     => 1,
                LocalPort => $port
            ) or die "ops $!";

            while (1) {
                $socket->accept()->close();
            }
        },
    );

    my $client = Riak::Light->new(
        host             => '127.0.0.1',
        port             => $server->port,
        timeout_provider => undef,
    );

    ok $client->has_pid, 'client should has pid';

    my $client_pid = $client->pid;

    is $client_pid, $$, 'should create pid with the current pid';
};
