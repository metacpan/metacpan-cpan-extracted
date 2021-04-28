use Test2::V0;

use lib 't/lib';

use Sub::Meta::Parameters;
use MySubMeta::Param;

my $p1 = Sub::Meta::Param->new(type => 'Str');
my $p2 = Sub::Meta::Param->new(type => 'Int');
my $p3 = Sub::Meta::Param->new(type => 'Num');
my $myp = MySubMeta::Param->new(type => 'MyStr');

subtest set_args => sub {
    my $parameters = Sub::Meta::Parameters->new(args => []);

    is $parameters->args, [], 'no args';

    is $parameters->set_args($p1), $parameters;
    is $parameters->args, [$p1], 'args: $p1';

    is $parameters->set_args($p2), $parameters;
    is $parameters->args, [$p2], 'args: $p2';

    is $parameters->set_args([$p1, $p2]), $parameters;
    is $parameters->args, [$p1, $p2], 'args: $p1, $p2';

    is $parameters->set_args($myp), $parameters;
    is $parameters->args, [$myp], 'args: $my param';

    my $some = bless {}, 'Some';
    is $parameters->set_args($some), $parameters;
    is $parameters->args, [Sub::Meta::Param->new(type => $some)], 'args: some object';

    my $sub = sub {};
    is $parameters->set_args($sub), $parameters;
    is $parameters->args, [Sub::Meta::Param->new(type => $sub)], 'args: sub';

    is $parameters->set_args({}), $parameters;
    is $parameters->args, [], 'args: { } / empty hashref';

    is $parameters->set_args({ a => 'Int' }), $parameters;
    is $parameters->args, [Sub::Meta::Param->new(type => 'Int', name => 'a', named => 1)], 'args: hashref';

    is $parameters->set_args({ a => 'Int', b => 'Str' }), $parameters;
    is $parameters->args, [
        Sub::Meta::Param->new(type => 'Int', name => 'a', named => 1),
        Sub::Meta::Param->new(type => 'Str', name => 'b', named => 1),
    ], 'args: { a => Int, b => Str }';

    is $parameters->set_args({ a => { type => 'Int', default => 1 } }), $parameters;
    is $parameters->args, [Sub::Meta::Param->new(type => 'Int', name => 'a', named => 1, default => 1)], 'args: { a => { type => Int, default => 1 } } / value is sub meta param args';

    is $parameters->set_args({ a => { name => 'hoge' } }), $parameters;
    is $parameters->args, [Sub::Meta::Param->new(name => 'hoge', named => 1)], 'args: { a => { name => hoge } } / override name';

    like dies { $parameters->set_args($p1, $p2) }, qr/args must be a single reference/;
    like dies { $parameters->set_args(1) },        qr/args must be a single reference/;
    like dies { $parameters->set_args('Str') },    qr/args must be a single reference/;
};

done_testing;

