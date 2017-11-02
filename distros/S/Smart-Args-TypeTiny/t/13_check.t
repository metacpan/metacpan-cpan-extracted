use Test2::V0;
use Smart::Args::TypeTiny::Check qw/check_rule check_type type type_role/;
use Types::Standard -all;

sub type_name {
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
    is check_rule({isa => Int, optional => 1},        undef, 1), undef;
    like dies { check_rule({isa => Int}, undef, 0, 'foo') },
        qr/Required parameter 'foo' not passed/;
    like dies { check_rule({isa => Int}, undef, 1, 'foo') },
        qr/Type check failed in binding to parameter '\$foo'; Undef did not pass type constraint "Int"/;
    like dies { check_rule({optioanl => 'Foo'}, undef, 0, 'foo') },
        qr/Malformed rule for 'foo' \(isa, does, optional, default\)/;
};

subtest 'check_type' => sub {
    is [check_type(Int, 1)], [1, 1];
    is [check_type(undef, 1)], [1, 1];
    is [check_type(ArrayRef->plus_coercions(Int, q{[$_]}), 1)], [[1], 1];
    is [check_type(Int, 'zero')], ['zero', 0];
};

subtest 'type' => sub {
    is type('Foo'), type_name('Foo');
    is type(InstanceOf['Foo']), type_name('InstanceOf["Foo"]');
    is type(Str), type_name('Str');
    is type('Str'), type_name('Str');
};

subtest 'type_role' => sub {
    is type_role('Bar'), type_name('Bar');
    is type_role(ConsumerOf['Bar']), type_name('ConsumerOf["Bar"]');
};

done_testing;
