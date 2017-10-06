use Test2::V0;
use Smart::Args::TypeTiny::Check qw/check_rule check_type/;
use Types::Standard -all;

sub type {
    my $name = shift;
    object {
        call display_name => $name;
    };
}

subtest 'check_rule' => sub {
    is check_rule({isa => Int}, 1, 1), 1;
    is check_rule({isa => Int, default => 99},        undef, 0), 99;
    is check_rule({isa => Int, default => sub { 1 }}, undef, 0), 1;
    is check_rule({isa => Int, optional => 1},        undef, 0), undef;
    like dies { check_rule({isa => Int}, undef, 0, 'foo') },
        qr/Required parameter 'foo' not passed/;
};

subtest 'check_type' => sub {
    is check_type(Int, 1), 1;
    is check_type(undef, 1), 1;
    is check_type(ArrayRef->plus_coercions(Int, q{[$_]}), 1), [1];
    like dies { check_type(Int, undef, 'foo') },
        qr/Type check failed in binding to parameter '\$foo'; Undef did not pass type constraint "Int"/;
};

subtest 'parameter_rule' => sub {
    subtest 'isa' => sub {
        is Smart::Args::TypeTiny::Check::parameter_rule('Foo'), {
            isa => type('InstanceOf["Foo"]'),
        };
        is Smart::Args::TypeTiny::Check::parameter_rule({isa => 'Foo'}), {
            isa => type('InstanceOf["Foo"]'),
        };
        is Smart::Args::TypeTiny::Check::parameter_rule({isa => InstanceOf['Foo']}), {
            isa => type('InstanceOf["Foo"]'),
        };
        is Smart::Args::TypeTiny::Check::parameter_rule({isa => Str}), {
            isa => type('Str'),
        };
    };

    subtest 'does' => sub {
        is Smart::Args::TypeTiny::Check::parameter_rule({does => 'Bar'}), {
            does => type('ConsumerOf["Bar"]'),
        };
        is Smart::Args::TypeTiny::Check::parameter_rule({does => ConsumerOf['Bar']}), {
            does => type('ConsumerOf["Bar"]'),
        };
    };

    subtest 'optional' => sub {
        is Smart::Args::TypeTiny::Check::parameter_rule({optional => 1}), {
            optional => 1,
        };
        is Smart::Args::TypeTiny::Check::parameter_rule({optional => 0}), {
            optional => 0,
        };
    };

    subtest 'default' => sub {
        is Smart::Args::TypeTiny::Check::parameter_rule({default => 1}), {
            default => 1,
        };
        is Smart::Args::TypeTiny::Check::parameter_rule({default => undef}), {
            default => undef,
        };
    };

    like dies { Smart::Args::TypeTiny::Check::parameter_rule({optioanl => 'Foo'}, 'foo') },
        qr/Malformed rule for 'foo' \(isa, does, optional, default\)/;
};

done_testing;
