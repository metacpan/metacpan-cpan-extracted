#!/usr/bin/env perl
use strict;
use warnings;

use Myriad;

{
    package Example::Service::RPC;

    # Simple RPC method example.

    use microservice;

    has $count = 0;

    async method current :RPC {
        return $count++;
    }

}

no indirect;

use Syntax::Keyword::Try;
use Future::AsyncAwait;
use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';
use Net::Async::Redis;
use IO::Async::Loop;

use Test::More;

my $loop = IO::Async::Loop->new();

$loop->add(my $send = Net::Async::Redis->new());
$loop->add(my $receive = Net::Async::Redis->new());

(async sub {
    my $myriad = Myriad->new;
    $myriad->add_service(
        'Example::Service::RPC'
    );
    {
        # TODO: This should be through service life cycle
        my $sub = await $receive->subscribe("client");
        my $f = $sub->events->map('payload')->decode('json')->map(sub {
            use Data::Dumper;
            warn Dumper(shift->{response});
        });

        for my $i (0 .. 100) {
            await $send->xadd("Example::Service::RPC", '*', rpc => "current", args => '{}', who => 'client', deadline => time + 1000, stash => '{}');
        }

        await $f->completed;
    }
})->()->get;

done_testing();
