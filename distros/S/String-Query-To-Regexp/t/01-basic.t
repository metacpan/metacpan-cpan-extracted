#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
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

my @data2 = (
    "aa",
    "a+",
);

my $re;

subtest "basics" => sub {
    dies_ok { query2re({foo=>1}) } 'unknown option -> dies';

    $re = query2re("foo");                                        is_deeply([grep {$_ =~ $re} @data1], [qw/foo foobar fooBAR barfoo/]);
    $re = query2re("foo", "bar");                                 is_deeply([grep {$_ =~ $re} @data1], [qw/foobar barfoo/]);
    $re = query2re("foo", "-bar");                                is_deeply([grep {$_ =~ $re} @data1], [qw/foo fooBAR/]);
    $re = query2re("a+");                                         is_deeply([grep {$_ =~ $re} @data2], [qw/a+/]); # test metachars
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

subtest "opt: re" => sub {
    $re = query2re({bool=>'or'}, "a", '/b/');                     is_deeply([grep {$_ =~ $re} "a", "b", "/b/"], [qw(a /b/)]);
    $re = query2re({bool=>'or', re=>1}, "a", '/b/');              is_deeply([grep {$_ =~ $re} "a", "b", "/b/"], [qw(a b /b/)]);
    $re = query2re({bool=>'or', re=>1}, "a", qr/b/);              is_deeply([grep {$_ =~ $re} "a", "b", "/b/"], [qw(a b /b/)]);
};


DONE_TESTING:
done_testing();
