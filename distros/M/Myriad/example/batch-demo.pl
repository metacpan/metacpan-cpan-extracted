#!/usr/bin/env perl 
use strict;
use warnings;

use Myriad;

{
package Example::Service::Batch;

# Simple batch method example.

use Myriad::Service;

has $count = 0;

async method current : RPC {
    return $count;
}

async method next_batch : Batch {
    return [ $count++ ];
}

}

no indirect;

use Syntax::Keyword::Try;
use Future::AsyncAwait;
use Log::Any qw($log);
use Test::More;

(async sub {
    my $myriad = Myriad->new;
    $myriad->add_service(
        'Example::Service::Batch',
        name => 'example_service_batch',
    );
    {
        my $srv = $myriad->service_by_name('example_service_batch');
        is(await $srv->current, 1, 'probably already at 1 because the first batch would have been called already');
        # Defer one iteration on the event loop
        await $myriad->loop->delay_future(after => 0);
        is(await $srv->current, 2, 'and now maybe we have 2');
    }
})->()->get;

done_testing();
