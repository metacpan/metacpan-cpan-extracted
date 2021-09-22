use Test2::V0;

use Types::Sub -types;
use Types::Standard -types;

subtest 'no arguments' => sub {
    ok Sub[] == Ref['CODE'];
    ok StrictSub[] == Ref['CODE'];
};

subtest 'check validation' => sub {
    my $case = { args => [Str], returns => Str };
    my $Sub           = Sub[$case];
    my $StrictSub     = StrictSub[$case];
    my $SubMeta       = SubMeta[$case];
    my $StrictSubMeta = StrictSubMeta[$case];

    subtest 'fail cases' => sub {
        my @tests = (
            Sub::Meta->new({ }), 'empty arguments',
            Sub::Meta->new({ args => [Int], returns => Str }), 'invalid args',
            Sub::Meta->new({ args => [Str], returns => Int }), 'invalid returns',
            Sub::Meta->new({ args => [Str], returns => [Str,Str]}), 'invalid returns',
            Sub::Meta->new({ args => [Str], returns => Str, is_method => 1 }), 'method(Str) => Str',
        );

        while (my ($meta, $message) = splice @tests, 0, 2) {
            my $v = sub {};
            Sub::Meta::Library->register($v, $meta);
            ok(!$Sub->check($v), "fail: Sub - $message");
            ok(!$StrictSub->check($v), "fail: StrictSub - $message");
            ok(!$SubMeta->check($meta), "fail: SubMeta - $message");
            ok(!$StrictSubMeta->check($meta), "fail: StrictSubMeta - $message");
        }
    };

    subtest 'pass Sub and StrictSub' => sub {
        my @tests = (
            Sub::Meta->new({ args => [Str], returns => Str }), 'sub(Str) => Str',
        );

        while (my ($meta, $message) = splice @tests, 0, 2) {
            my $v = sub {};
            Sub::Meta::Library->register($v, $meta);
            ok($Sub->check($v), "pass: Sub - $message");
            ok($StrictSub->check($v), "pass: StrictSub - $message");
            ok($SubMeta->check($meta), "pass: SubMeta - $message");
            ok($StrictSubMeta->check($meta), "pass: StrictSubMeta - $message");
        }
    };

    subtest 'pass only Sub' => sub {
        my @tests = (
            Sub::Meta->new(args => [Str, Str], returns => Str), 'sub(Str, Str) => Str',
            Sub::Meta->new(args => [Str, Int], returns => Str), 'sub(Str, Int) => Str',
        );

        while (my ($meta, $message) = splice @tests, 0, 2) {
            my $v = sub {};
            Sub::Meta::Library->register($v, $meta);
            ok($Sub->check($v), "pass: Sub - $message");
            ok(!$StrictSub->check($v), "fail: StrictSub - $message");
            ok($SubMeta->check($meta), "pass: SubMeta - $message");
            ok(!$StrictSubMeta->check($meta), "fail: StrictSubMeta - $message");
        }
    };
};

subtest 'Sub/message' => sub {
    my $Sub = Sub[
        args    => [Int,Int],
        returns => Int
    ];

    ## no critic qw(RegularExpressions::ProhibitComplexRegexes)
    subtest 'case: sub {}' => sub {
        my $message = $Sub->get_message(sub {});
        my @m = split /\n/, $message;

        is @m, 4;
        like $m[0], qr/^Reference sub \{ "DUMMY" \} did not pass type constraint "Sub\[sub\(Int, Int\) => Int\]"/;
        like $m[1], qr/^    Reason/;
        like $m[2], qr/^    Expected/;
        like $m[3], qr/^    Got/;
    };

    subtest 'case: undef' => sub {
        my $message = $Sub->get_message(undef);
        my @m = split /\n/, $message;

        is @m, 2;
        like $m[0], qr/^Undef did not pass type constraint "Sub\[sub\(Int, Int\) => Int\]"/;
        like $m[1], qr/^    Cannot find submeta of `Undef`/;
    };
};

subtest 'SubMeta/exceptions' => sub {
    ok dies { SubMeta[ [Str] ] };
    ok dies { SubMeta[ '' ] };
    ok dies { SubMeta[ \''] };
    ok dies { SubMeta[ sub {} ] };
};

subtest 'SubMeta/coerce' => sub {
    my $type = SubMeta[ args => [Str] ];
    is $type->coerce('hello'), 'hello';
    my $sub = sub {};
    is $type->coerce($sub), Sub::Meta->new(sub => $sub);
};
done_testing;
