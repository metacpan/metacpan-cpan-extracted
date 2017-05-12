use strict;
use warnings;
use lib 't/lib';
use Test::More;

eval {
    require Module::Requires;
    Module::Requires->import('ClassA');
};
is($@, '');
is(ClassA->package, 'ClassA');

done_testing;
