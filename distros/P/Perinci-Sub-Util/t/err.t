#!perl

use 5.010;
use strict;
use warnings;

use Gen::Test::Rinci::FuncResult qw(gen_test_func);
use Test::More 0.98;

use Perinci::Sub::Util qw(err);

gen_test_func(func => \&err, name => 'test_err');

package Foo;

sub bar {
    my $res = Perinci::Sub::Util::err();
    #use Data::Dump; dd $res;
    $res;
}

package main;

test_err(
    name     => 'defaults',
    args     => [],
    status   => 500,
    message  => "(eval) failed",
    result   => undef,
    posttest => sub {
        my $res = shift;
        is(ref($res->[3]), 'HASH', 'result metadata is hash');
    },
);

test_err(
    name     => 'set status',
    args     => [400],
    status   => 400,
);

test_err(
    name     => 'set message',
    args     => ["some message"],
    status   => 500,
    message  => "some message",
);

test_err(
    name     => 'set prev',
    args     => ["some message", 400, [401, "prev error"]],
    status   => 400,
    message  => "some message",
    posttest => sub {
        my $res = shift;
        is_deeply($res->[3]{prev}, [401, "prev error"], "prev");
    },
);

{
    test_err(
        name     => 'caller',
        run      => sub { Foo::bar() }, # line 63
        status   => 500,
        message  => "Foo::bar failed",
        posttest => sub {
            my $res = shift;
            is($res->[3]{logs}[0]{type}, "create", "log[0] type");
            ok($res->[3]{logs}[0]{time}, "log[0] time");
            is($res->[3]{logs}[0]{package}, "main", "log[0] package");
            is($res->[3]{logs}[0]{func}, "Foo::bar", "log[0] func");
            is($res->[3]{logs}[0]{line}, 63, "log[0] line");
        },
    );
}

{
    local %INC = %INC;
    $INC{"Carp/Always.pm"} = "test";
    my $res1;
    test_err(
        name     => 'stack_trace',
        run      => sub { Foo::bar() },
        status   => 500,
        posttest => sub {
            my $res = shift;
            #use Data::Dump; dd $res;
            ok($res->[3]{logs}[0]{stack_trace}, "stack_trace");
            $res1 = $res;
        },
    );

    test_err(
        name     => 'stack_trace only produced once',
        args     => [$res1, 501],
        status   => 501,
        posttest => sub {
            my $res = shift;
            #use Data::Dump; dd $res;
            ok(!$res->[3]{logs}[0]{stack_trace}, "stack_trace");
        },
    );
}

DONE_TESTING:
done_testing();
