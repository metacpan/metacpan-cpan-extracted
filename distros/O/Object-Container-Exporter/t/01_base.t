use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Mock::Container;

subtest 'export container function' => sub {

    eval { container('foo') };
    isa_ok container('foo'), 'Mock::Foo';
    is container('foo')->say, 'foo';

    eval { container('bar') };
    ok $@;
};

done_testing;


