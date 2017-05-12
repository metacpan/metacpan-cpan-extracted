use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Mock::Container;

subtest 'remove' => sub {
    my $foo = container('foo');
    Mock::Container->remove('foo');
    my $foo2 = container('foo');

    isnt $foo, $foo2;
};

done_testing;

