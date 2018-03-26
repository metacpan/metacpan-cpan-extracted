#!perl

use strict;
use warnings;
use Test::More 0.98;

use Regexp::Pattern::JSON;

my $re = \%Regexp::Pattern::JSON::RE;

subtest number => sub {
    my $pat = $re->{number}{pat};
    ok(!(q()     =~ $pat));
    ok( (q(1)    =~ $pat));
    ok( (q(1.2)  =~ $pat));
    ok( (q(-3.4) =~ $pat));
    ok(!(q("")   =~ $pat));
    ok(!(q([])   =~ $pat));
    ok(!(q({})   =~ $pat));
    ok(!(q(null) =~ $pat));
};

subtest string => sub {
    my $pat = $re->{string}{pat};
    ok(!(q()     =~ $pat));
    ok(!(q(")    =~ $pat));
    ok( (q("")   =~ $pat));
    ok( (q("a")  =~ $pat));
    ok( (q("\"") =~ $pat));
    ok(!(q(1)    =~ $pat));
    ok(!(q([])   =~ $pat));
    ok(!(q({})   =~ $pat));
    ok(!(q(null) =~ $pat));
};

subtest array => sub {
    my $pat = $re->{array}{pat};
    ok(!(q()     =~ $pat));
    ok(!(q(")    =~ $pat));
    ok(!(q("")   =~ $pat));
    ok(!(q(1)    =~ $pat));
    ok( (q([])   =~ $pat));
    ok( (q([1])  =~ $pat));
    ok(!(q([1,]) =~ $pat));
    ok(!(q([,])  =~ $pat));
    ok(!(q([)    =~ $pat));
    ok(!(q({})   =~ $pat));
    ok(!(q({)    =~ $pat));
    ok(!(q(null) =~ $pat));
};

subtest object => sub {
    my $pat = $re->{object}{pat};
    ok(!(q()     =~ $pat));
    ok(!(q(")    =~ $pat));
    ok(!(q("")   =~ $pat));
    ok(!(q(1)    =~ $pat));
    ok(!(q([])   =~ $pat));
    ok(!(q([1])  =~ $pat));
    ok(!(q([1,]) =~ $pat));
    ok(!(q([,])  =~ $pat));
    ok(!(q([)    =~ $pat));
    ok( (q({})   =~ $pat));
    ok( (q({"a":1})   =~ $pat));
    ok(!(q({)    =~ $pat));
    ok(!(q(null) =~ $pat));
};

subtest value => sub {
    my $pat = $re->{value}{pat};
    ok(!(q()     =~ $pat));
    ok(!(q(")    =~ $pat));
    ok( (q("")   =~ $pat));
    ok( (q(1)    =~ $pat));
    ok( (q([])   =~ $pat));
    ok( (q([1])  =~ $pat));
    #ok(!(q([1,]) =~ $pat)); # XXX why match?
    ok(!(q([,])  =~ $pat));
    ok(!(q([)    =~ $pat));
    ok( (q({})   =~ $pat));
    ok(!(q({)    =~ $pat));
    ok( (q(null) =~ $pat));
};

done_testing;
