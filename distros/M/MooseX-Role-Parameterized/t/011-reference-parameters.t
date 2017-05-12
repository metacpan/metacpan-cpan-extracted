use strict;
use warnings;
use Test::More 0.88;

do {
    package MyRole::Delegator;
    use MooseX::Role::Parameterized;

    parameter handles => (
        is       => 'rw',
        required => 1,
    );

    role {
        my $p = shift;

        has attr => (
            is      => 'rw',
            isa     => 'MyClass::WithMethods',
            handles => $p->handles,
        );
    };
};

do {
    package MyClass::WithMethods;
    use Moose;

    sub foo { "foo" }
    sub bar { "bar" }
    sub baz { "baz" }
};

do {
    package MyArrayConsumer;
    use Moose;
    with 'MyRole::Delegator' => {
        handles => ['foo', 'bar'],
    };
};

can_ok(MyArrayConsumer => 'foo', 'bar');
cant_ok(MyArrayConsumer => 'baz');

do {
    package MyRegexConsumer;
    use Moose;
    with 'MyRole::Delegator' => {
        handles => qr/^ba/,
    };
};

can_ok(MyRegexConsumer => 'bar', 'baz');
cant_ok(MyRegexConsumer => 'foo');

do {
    package MyHashConsumer;
    use Moose;
    with 'MyRole::Delegator' => {
        handles => {
            my_foo => 'foo',
            his_baz => 'baz',
        },
    };
};

can_ok(MyHashConsumer => 'my_foo', 'his_baz');
cant_ok(MyHashConsumer => qw/foo bar baz/);

sub cant_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $instance = shift;
    for my $method (@_) {
        ok(!$instance->can($method), "$instance cannot $method");
    }
}

done_testing;
