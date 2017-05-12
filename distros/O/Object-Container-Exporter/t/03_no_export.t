use strict;
use warnings;
use lib './t/lib';
use Mock::Container -no_export;
use Test::More;

subtest 'no export container' => sub {
    ok not main->can('container');
};

subtest 'instance' => sub {
    my $obj = Mock::Container->instance;
    isa_ok $obj, 'Mock::Container';
    is $obj->get('foo')->say, 'foo';
};

done_testing;

