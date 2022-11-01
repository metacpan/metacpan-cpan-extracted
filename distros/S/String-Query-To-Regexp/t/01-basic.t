#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use String::Query::To::Regexp qw(
                                  query2re
                          );

my @data1 = (
    "foo",
    "FOO",
    "bar",
    "foobar",
    "fooBAR",
    "barfoo",
);

my $re;

subtest "basics" => sub {
    $re = query2re("foo");                                        is_deeply([grep {$_ =~ $re} @data1], [qw/foo foobar fooBAR barfoo/]);
    $re = query2re("foo", "bar");                                 is_deeply([grep {$_ =~ $re} @data1], [qw/foobar barfoo/]);
    $re = query2re("foo", "-bar");                                is_deeply([grep {$_ =~ $re} @data1], [qw/foo fooBAR/]);
    note explain [grep {$_ =~ $re} @data1];
};


subtest "opt: ci" => sub {
    $re = query2re({ci=>1}, "foo", "bar");                        is_deeply([grep {$_ =~ $re} @data1], [qw/foobar fooBAR barfoo/]);
};

subtest "opt: word" => sub {
    $re = query2re({word=>1},"foo");                              is_deeply([grep {$_ =~ $re} @data1], [qw/foo/]);
};

subtest "opt: bool" => sub {
    $re = query2re({bool=>'or'},"foo", "bar");                    is_deeply([grep {$_ =~ $re} @data1], [qw/foo bar foobar fooBAR barfoo/]);
};


DONE_TESTING:
done_testing();
