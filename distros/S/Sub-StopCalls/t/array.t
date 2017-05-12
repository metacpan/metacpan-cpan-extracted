#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;

use_ok('Sub::StopCalls');
#use B::Concise ();

my $i = 0;

sub foo {
    $i++;
    return Sub::StopCalls::stop(qw(foo bar baz));
}

my @subs = (
sub {
    my @a = foo();
    is_deeply(\@a, [qw(foo bar baz)]);
    return 1;
},
sub {
    my @a = (foo());
    is_deeply(\@a, [qw(foo bar baz)]);
    return 1;
},
sub {
    my @a = (foo())[0];
    is_deeply(\@a, [qw(foo)]);
    return 1;
},
sub {
    my @a = ('const', foo(), 'const');
    is_deeply(\@a, [qw(const foo bar baz const)]);
    return 1;
},
sub {
    my ($x, $y) = foo();
    is_deeply([$x,$y], [qw(foo bar)]);
    return 1;
},
sub {
    my $x = foo();
    is($x,3);
    return 1;
},
);

foreach my $sub (@subs) {
    my $cur = $i;
#    B::Concise::compile($sub)->();
    $sub->();
#    B::Concise::compile($sub)->();
    is( $i, $cur + 1 );
    $sub->();
    is( $i, $cur + 1 );
}

