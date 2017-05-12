use strict;
use warnings;
use Test::More 0.88;

my @calls;

do {
    package MyRole::LogMethod;
    use MooseX::Role::Parameterized;

    parameter method => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    role {
        my $p = shift;

        override $p->method => sub {
            push @calls, "calling " . $p->method;
            super;
            push @calls, "called " . $p->method;
        };
    };
};

do {
    package MyClass;
    use Moose;
    with 'MyRole::LogMethod' => {
        method => 'new',
    };
};

is_deeply([splice @calls], [], "no calls yet");
MyClass->new;
is_deeply([splice @calls], ["calling new", "called new"], "instrumented new");

done_testing;
