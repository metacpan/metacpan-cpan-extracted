use strict;
use warnings;
use Test::More;

{
    package Mock;
    use Sub::Args;

    sub new {bless {}, +shift}
    sub foo {
        my $args = args(
            {
                name => 1,
                age  => 0,
            }
        );
        $args;
    }

    sub bar {
        args('bbb');
    }

    sub baz {
        my $class = shift;
        my $args = args(
            {
                name => 1,
                age  => 0,
            }, @_
        );
        $args;
    }

    sub no_lock_key_access {
        my $class = shift;
        my $args = args({name => 1, age => 0});
        local $SIG{__WARN__} = sub {};
        warn $args->{name};
        warn $args->{age};
        warn $args->{error};
    }
}

subtest 'no_lock_key' => sub {
    eval {
        Mock->no_lock_key_access({name => 'nekokak', age => 32});
    };
    like $@, qr/Attempt to access disallowed key 'error' in a restricted hash at/;
    eval {
        Mock->no_lock_key_access({name => 'nekokak'});
    };
    like $@, qr/Attempt to access disallowed key 'error' in a restricted hash at/;
    ok 1;
};

subtest 'success case / no invocant' => sub {
    {
        package Mock::IV;
        use Sub::Args;

        sub foo {
            my $args = args(
                {
                    name => 1,
                    age  => 0,
                }
            );
            $args;
        }

        ::is_deeply foo({name => 'nekokak'}), +{name => 'nekokak', age => undef};
        ::is_deeply foo({name => 'nekokak', age => 32}), +{name => 'nekokak', age => 32};
        ::is_deeply foo(name => 'nekokak'), +{name => 'nekokak', age => undef};
    }
};

subtest 'success case / no @_' => sub {
    is_deeply +Mock->foo({name => 'nekokak'}), +{name => 'nekokak', age => undef};
    is_deeply +Mock->foo({name => 'nekokak', age => 32}), +{name => 'nekokak', age => 32};
    is_deeply +Mock->foo(name => 'nekokak'), +{name => 'nekokak', age => undef};
};

subtest 'success case / use @_' => sub {
    is_deeply +Mock->baz({name => 'nekokak'}), +{name => 'nekokak', age => undef};
    is_deeply +Mock->baz({name => 'nekokak', age => 32}), +{name => 'nekokak', age => 32};
    is_deeply +Mock->baz(name => 'nekokak'), +{name => 'nekokak', age => undef};
};

subtest 'success case / obj / use @_' => sub {
    my $obj = Mock->new;
    is_deeply $obj->foo({name => 'nekokak'}), +{name => 'nekokak', age => undef};
    is_deeply $obj->foo({name => 'nekokak', age => 32}), +{name => 'nekokak', age => 32};
    is_deeply $obj->foo(name => 'nekokak'), +{name => 'nekokak', age => undef};
};

subtest 'error case' => sub {
    eval {
        Mock->foo({name => 'nekokak', age => 32, nick => 'inukaku'});
    };
    like $@, qr/not listed in the following parameter: nick./;

    eval {
        Mock->foo(name => 'nekokak', age => 32, nick => 'inukaku');
    };
    like $@, qr/not listed in the following parameter: nick./;

    eval {
        Mock->foo({age => 32});
    };
    like $@, qr/Mandatory parameter 'name' missing./;

    eval {
        Mock->foo(age => 32);
    };
    like $@, qr/Mandatory parameter 'name' missing./;

    eval {
        Mock->bar({age => 32});
    };
    like $@, qr/args method require hashref's rule./;

    eval {
        Mock->bar(age => 32);
    };
    like $@, qr/args method require hashref's rule./;

    eval {
        Mock->foo('aaa');
    };
    like $@, qr/not allow excluding hash or hashref/;
};

done_testing;

1;

