use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Mock::AnotherContainer;

subtest 'export specific container function' => sub {

    eval { obj('foo') };
    isa_ok obj('foo'), 'Mock::Foo';
    is obj('foo')->say, 'foo';

    eval { obj('bar') };
    ok $@;
};

done_testing;
