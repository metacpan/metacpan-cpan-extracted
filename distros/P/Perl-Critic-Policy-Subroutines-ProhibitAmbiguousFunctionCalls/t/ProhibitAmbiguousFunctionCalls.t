#!/bin/env perl

## Test file for Perl::Critic::Policy::Subroutines::ProhibitAmbiguosFunctionNames

use strict;
use warnings;
use Test::More;
use Test::Deep;

use Perl::Critic;

my $policy = 'Subroutines::ProhibitAmbiguousFunctionCalls';
(my $shortpolicy = $policy) =~ s/.*:://;

my $c = Perl::Critic->new(-"single-policy" => $shortpolicy);

my $test = 'Only checking a single policy';
my @list = map { "$_" } $c->policies();
cmp_deeply(\@list, [$policy], $test);

$test = 'Policy is not triggered by a normal function call';
my $string = 'print Foo::Bar';
my $result = $c->critique(\$string);

$test   = 'Policy is NOT triggered by Foo::bar->pop';
$string = 'print Foo::Bar->pop;';
$result = $c->critique(\$string);
is($result, 0, $test);

for my $method (qw/ new add  /) {
    $test   = "Policy is NOT triggered when method name is '$method'";
    $result = $c->critique(\ "print Foo::bar->$method");
    is($result, 0, $test);
}

for my $method (qw/ pop NEW New /) {
    $test   = "Policy is triggered by when method name is '$method";
    $result = $c->critique(\ "print Foo::bar->$method");
    is($result, 1, $test);
}

for my $method (qw/ timey wimey /) {
    $test                                                       = "Policy is NOT triggered when method name is '$method' (put there by config)";
    $c->config->{_policies}->[0]->{_methods_always_ok}{$method} = 1;
    $result                                                     = $c->critique(\ "print Foo::bar->$method");
    is($result, 0, $test);
}

$test   = "Policy is NOT triggered by methods with parens, such as Foo::Bar->pop()";
$result = $c->critique(\ "print Foo::Bar->pop()");
is($result, 0, $test);

$test = 'Policy IS triggered by methods with uppercase, when uppercase_module_always_ok set as false';
$c->config->{_policies}->[0]->{_uppercase_module_always_ok} = 0;
$result = $c->critique(\ "print Foo::Bar->pop");
is($result, 1, $test);

done_testing();
