#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Package::Stash;

my $stash = Package::Stash->new('Foo');
$stash->add_symbol('%foo', {bar => 1});
{
    no warnings 'once';
    is($Foo::foo{bar}, 1, "set in the stash properly");
}
ok(!$stash->has_symbol('$foo'), "doesn't have anything in scalar slot");
my $namespace = $stash->namespace;
is_deeply(*{ $namespace->{foo} }{HASH}, {bar => 1}, "namespace works properly");

done_testing;
