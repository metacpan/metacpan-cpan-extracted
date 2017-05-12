#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Stash::Manip;

my $stash = Stash::Manip->new('Foo');
$stash->add_package_symbol('%foo', {bar => 1});
{
    no warnings 'once';
    is($Foo::foo{bar}, 1, "set in the stash properly");
}
ok(!$stash->has_package_symbol('$foo'), "doesn't have anything in scalar slot");
my $namespace = $stash->namespace;
is_deeply(*{ $namespace->{foo} }{HASH}, {bar => 1}, "namespace works properly");

done_testing;
