#!perl -w
use strict;
use Test::More;

use Sub::Spy;
use Sub::Spy::Call;

subtest("new", sub {
    my $call = Sub::Spy::Call->new(+{
        args => [1, 2, 3],
        exception => "die",
        return_value => 1,
    });

    is_deeply( $call->args, [1, 2, 3] );
    is( $call->exception, "die" );
    is( $call->return_value, 1 );
    ok( $call->threw );
});

done_testing;
