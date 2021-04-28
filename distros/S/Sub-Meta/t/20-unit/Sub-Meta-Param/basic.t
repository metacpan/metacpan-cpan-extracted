use Test2::V0;

use Sub::Meta::Param;
use Sub::Meta::Test qw(sub_meta_param);

subtest 'no arg' => sub {
    my $param = Sub::Meta::Param->new;
    is $param, sub_meta_param();
};

subtest 'arg: type => Str' => sub {
    my $param = Sub::Meta::Param->new({ type => 'Str' });
    is $param, sub_meta_param({
        type => 'Str',
    });
};

subtest 'arg: name => $a' => sub {
    my $param = Sub::Meta::Param->new({ name => '$a' });
    is $param, sub_meta_param({
        name => '$a',
    });
};

subtest 'arg: default => hoge' => sub {
    my $param = Sub::Meta::Param->new({ default => 'hoge' });
    is $param, sub_meta_param({
        default => 'hoge',
    });
};

subtest 'arg: coerce => $sub' => sub {
    my $sub = sub { };
    my $param = Sub::Meta::Param->new({ coerce => $sub });
    is $param, sub_meta_param({
        coerce => $sub,
    });
};

subtest 'arg: optional => !!1' => sub {
    my $param = Sub::Meta::Param->new({ optional => !!1 });
    is $param, sub_meta_param({
        optional => !!1,
    });
};

subtest 'arg: named => !!1' => sub {
    my $param = Sub::Meta::Param->new({ named => !!1 });
    is $param, sub_meta_param({
        named => !!1,
    });
};

subtest 'arg: invocant => !!1' => sub {
    my $param = Sub::Meta::Param->new({ invocant => !!1 });
    is $param, sub_meta_param({
        invocant => !!1,
    });
};

subtest 'single arg is treated as a type' => sub {
    is(
        Sub::Meta::Param->new('Str'),
        sub_meta_param({ type => 'Str' })
    );

    is(
        Sub::Meta::Param->new([]),
        sub_meta_param({ type => [] })
    );

    my $type = sub {};
    is(
        Sub::Meta::Param->new($type),
        sub_meta_param({ type => $type })
    );

    my $type2 = bless {}, 'Type';
    is(
        Sub::Meta::Param->new($type2),
        sub_meta_param({ type => $type2 })
    );
};

subtest 'mixed arg' => sub {
    my $param = Sub::Meta::Param->new({
        type     => 'Int',
        name     => '$num',
        default  => 999,
        coerce   => undef,
        optional => !!1,
        named    => !!1,
    });
    is $param, sub_meta_param({
        type     => 'Int',
        name     => '$num',
        default  => 999,
        coerce   => undef,
        optional => !!1,
        named    => !!1,
    });
};

subtest 'other mixed arg' => sub {
    my $default = sub {};
    my $param = Sub::Meta::Param->new({
        type     => 'Int',
        name     => '$num',
        default  => $default,
    });
    is $param, sub_meta_param({
        type     => 'Int',
        name     => '$num',
        default  => $default,
        optional => !!0,
        named    => !!0,
    });
};

done_testing;
