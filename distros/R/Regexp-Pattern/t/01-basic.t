#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Regexp::Pattern;

dies_ok { re("Example::foo") } "get unknown -> dies";

subtest "get" => sub {
    my $re1 = re("Example::re1");
    ok $re1;
    ok('123-4567' =~ $re1);
    ok(!('foo' =~ $re1));
};

subtest "get dynamic" => sub {
    my $re3a = re("Example::re3", variant => 'A');
    ok $re3a;
    ok('123-456' =~ $re3a);
    ok(!('foo' =~ $re3a));
    my $re3b = re("Example::re3", variant => 'B');
    ok $re3b;
    ok('123-45-67890' =~ $re3b);
    ok(!('123-456' =~ $re3b));
};



done_testing;
