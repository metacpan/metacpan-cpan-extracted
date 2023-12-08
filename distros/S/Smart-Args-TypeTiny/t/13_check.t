use Test2::V0;
use Smart::Args::TypeTiny::Check qw/check_rule no_check_rule check_type type type_role/;
use Types::Standard -all;

sub type_name {
    my $name = shift;
    object {
        call display_name => $name;
    };
}

{
    # common test cases for check_rule and no_check_rule
    my @tests = (
        {
            test     => 'When a rule is not hashref',
            args     => [Int, 123, 1, 'foo'],
            expected => 123,
        },
        {
            test     => 'When a rule is hashref',
            args     => [{isa => Int}, 123, 1, 'foo'],
            expected => 123,
        },
        {
            test     => 'Not given a value but has default, return the default',
            args     => [{isa => Int, default => 99}, undef, 0, 'foo'],
            expected => 99,
        },
        {
            test     => 'Not given a value but has default coderef, return the result of default coderef',
            args     => [{isa => Int, default => sub { 123 }}, undef, 0, 'foo'],
            expected => 123,
        },
        {
            test     => 'Not given a value but optional, return undef',
            args     => [{isa => Int, optional => 1}, undef, 0, 'foo'],
            expected => undef,
        },
        {
            test     => 'Given a undefined value and optional, return undef',
            args     => [{isa => Int, optional => 1}, undef, 1, 'foo'],
            expected => undef,
        },
        {
            test     => 'Not given a value but not optional, throw an exception',
            args     => [{isa => Int}, undef, 0, 'foo'],
            throw    => qr/Required parameter 'foo' not passed/,
        },
        {
            test => 'Malformed rule',
            args => [{optioanl => 'Foo'}, undef, 0, 'foo'],
            throw => qr/Malformed rule for 'foo' \(isa, does, optional, default\)/,
        },
    );

    my @type_tests = (
        {
            test     => '123 is Int',
            args     => [Int, 123, 1, 'foo'],
            expected => 123,
        },
        {
            test     => '"Hello" is not Int',
            args     => [Int, 'Hello', 1, 'foo'],
            throw    => qr/Type check failed in binding to parameter '\$foo'; Value "Hello" did not pass type constraint "Int"/,
        },
        {
            test     => 'Undef is not Int',
            args     => [Int, undef, 1, 'foo'],
            throw    => qr/Type check failed in binding to parameter '\$foo'; Undef did not pass type constraint "Int"/,
        },
        {
            test     => '123 is not AraayRef',
            args     => [ArrayRef, 123, 1, 'foo'],
            throw    => qr/Type check failed in binding to parameter '\$foo'; Value "123" did not pass type constraint "ArrayRef"/,
        },
        {
            test     => 'ArrayRef with coercion',
            args     => [ArrayRef->plus_coercions(Int, q{[$_]}), 123, 1, 'foo'],
            expected => [123],
            no_check_rule_expected => 123, # no_check_rule does not coerce value
        },
    );

    subtest 'check_rule' => sub {
        for (@tests) {
            my ($test, $args, $expected, $throw) = @{$_}{qw/test args expected throw/};
            my ($rule, $value, $exists, $name) = @$args;

            if ($throw) {
                like dies { check_rule($rule, $value, $exists, $name) }, $throw, $test;
            } else {
                is check_rule($rule, $value, $exists, $name), $expected, $test;
            }
        }

        subtest 'Throw an exception if the type check fails' => sub {
            for (@type_tests) {
                my ($test, $args, $expected, $throw) = @{$_}{qw/test args expected throw/};
                my ($rule, $value, $exists, $name) = @$args;
                if ($throw) {
                    like dies { check_rule($rule, $value, $exists, $name) }, $throw, $test;
                } else {
                    is check_rule($rule, $value, $exists, $name), $expected, $test;
                }
            }
        }
    };

    subtest 'no_check_rule' => sub {
        for (@tests) {
            my ($test, $args, $expected, $throw) = @{$_}{qw/test args expected throw/};
            my ($rule, $value, $exists, $name) = @$args;

            if ($throw) {
                like dies { no_check_rule($rule, $value, $exists, $name) }, $throw, $test;
            } else {
                is no_check_rule($rule, $value, $exists, $name), $expected, $test;
            }
        }

        subtest '*Not* throw an exception if the type check fails' => sub {
            for (@type_tests) {
                my ($test, $args, $expected, $throw, $no_check_rule_expected) = @{$_}{qw/test args expected throw no_check_rule_expected/};
                my ($rule, $value, $exists, $name) = @$args;
                if ($throw) {
                    # not dies
                    ok lives { no_check_rule($rule, $value, $exists, $name) }, $test;
                } elsif (defined $no_check_rule_expected) {
                    is no_check_rule($rule, $value, $exists, $name), $no_check_rule_expected, $test . ' (no_check_rule)';
                } else {
                    is no_check_rule($rule, $value, $exists, $name), $expected, $test;
                }
            }
        }
    };
};

subtest 'check_type' => sub {
    is [check_type(Int, 1)], [1, 1];
    is [check_type(undef, 1)], [1, 1];
    is [check_type(ArrayRef->plus_coercions(Int, q{[$_]}), 1)], [[1], 1];
    is [check_type(Int, 'zero')], ['zero', 0];
};

subtest 'type' => sub {
    is type('Foo'), type_name('Foo');
    my $instance_of_foo = InstanceOf['Foo'];
    is type($instance_of_foo), exact_ref($instance_of_foo);
    my $str = Str;
    is type($str), exact_ref($str);
    is type('Str'), type_name('Str');
};

subtest 'type_role' => sub {
    is type_role('Bar'), type_name('Bar');
    my $consumer_of_bar = ConsumerOf['Bar'];
    is type($consumer_of_bar), exact_ref($consumer_of_bar);
};

done_testing;
