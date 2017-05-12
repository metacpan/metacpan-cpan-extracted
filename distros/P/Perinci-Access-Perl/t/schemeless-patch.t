#!perl

# test that patching the module works

use 5.010;
use strict;
use warnings;

use Perinci::Access::Schemeless;
use Test::More 0.98;

my $pa = Perinci::Access::Schemeless->new;

package Perinci::Access::Schemeless;

sub actionmeta_foo { +{
    applies_to => ['*'],
    summary    => 'Test',
    needs_meta => 0,
    needs_code => 0,
} }
sub action_foo {
    [200];
}

package main;

ok($pa->request(foo => "/"));
done_testing;
