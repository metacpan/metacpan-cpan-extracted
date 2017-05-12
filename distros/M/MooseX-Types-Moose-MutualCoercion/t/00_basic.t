#!perl

use strict;
use warnings;

use lib 't/lib';

my @TYPE_NAMES;
BEGIN {
    @TYPE_NAMES = qw(
        NumToInt
        ScalarRefToStr      ArrayRefToLines
        StrToClassName
        StrToScalarRef
        StrToArrayRef       LinesToArrayRef
        HashRefToArrayRef   HashKeysToArrayRef  HashValuesToArrayRef
        OddArrayRef         EvenArrayRef
        ArrayRefToHashRef   ArrayRefToHashKeys
        ArrayRefToRegexpRef
    );
}

{
    package Foo;

    use Moose;
    use MooseX::Types::Moose::MutualCoercion (@TYPE_NAMES);

    use namespace::clean -except => [qw(meta)];

    my @cliche = (is => 'rw', coerce => 1, 'isa');

    has numtoint             => ( @cliche, NumToInt             );
    has scalarreftostr       => ( @cliche, ScalarRefToStr       );
    has arrayreftolines      => ( @cliche, ArrayRefToLines      );
    has strtoclassname       => ( @cliche, StrToClassName       );
    has strtoscalarref       => ( @cliche, StrToScalarRef       );
    has strtoarrayref        => ( @cliche, StrToArrayRef        );
    has linestoarrayref      => ( @cliche, LinesToArrayRef      );
    has hashreftoarrayref    => ( @cliche, HashRefToArrayRef    );
    has hashkeystoarrayref   => ( @cliche, HashKeysToArrayRef   );
    has hashvaluestoarrayref => ( @cliche, HashValuesToArrayRef );
    has oddarrayref          => ( @cliche, OddArrayRef          );
    has evenarrayref         => ( @cliche, EvenArrayRef         );
    has arrayreftohashref    => ( @cliche, ArrayRefToHashRef    );
    has arrayreftohashkeys   => ( @cliche, ArrayRefToHashKeys   );
    has arrayreftoregexpref  => ( @cliche, ArrayRefToRegexpRef  );

    __PACKAGE__->meta->make_immutable;
    1;
}
{
    # use Test::Exception;
    use Class::Load qw(is_class_loaded);
    use Test::More;

    BEGIN {
        plan tests => scalar @TYPE_NAMES
                    + 2; # "use_ok", "ensure class loaded"
        use_ok 'MooseX::Types::Moose::MutualCoercion';
    }

    my $foo = Foo->new;

    is(
        $foo->numtoint(3.14),
        3,
        'coercion of NumToInt'
    );

    is(
        $foo->scalarreftostr(\do{ 'foo' }),
        'foo',
        'coercion of ScalarRefToStr'
    );

    is(
        $foo->arrayreftolines([qw(foo bar baz qux)]),
        "foo\nbar\nbaz\nqux\n",
        'coercion of ArrayRefToLines'
    );

    is(
        $foo->strtoclassname('Test::SomeClass'),
        'Test::SomeClass',
        'coercion of StrToClassName'
    );
    ok(
        is_class_loaded('Test::SomeClass'),
        'ensure class loaded',
    );

    is_deeply(
        $foo->strtoscalarref('foo'),
        \'foo',
        'coercion of StrToScalarRef'
    );

    is_deeply(
        $foo->strtoarrayref('element0'),
        [qw(element0)],
        'coercion of StrToArrayRef' );

    is_deeply(
        $foo->linestoarrayref("element0\nelement1\nelement2\n"),
        [("element0\n", "element1\n", "element2\n")],
        'coercion of LinesToArrayRef'
    );

    is_deeply(
        $foo->hashreftoarrayref({ a => 2, b => 1, c => 0 }),
        [qw(a 2 b 1 c 0)],
        'coercion of HashRefToArrayRef'
    );

    is_deeply(
        $foo->hashkeystoarrayref({ d => 5, e => 4, f => 3 }),
        [qw(d e f)],
        'coercion of HashKeysToArrayRef'
    );

    is_deeply(
        $foo->hashvaluestoarrayref({ g => 8, h => 7, i => 6 }),
        [qw(8 7 6)],
        'coercion of HashValuesToArrayRef'
    );

    is_deeply(
        $foo->oddarrayref([qw(element0 element1)]),
        [qw(element0 element1), undef],
        'coercion of OddArrayRef'
    );

    is_deeply(
        $foo->evenarrayref([qw(element0 element1 element2)]),
        [qw(element0 element1 element2), undef],
        'coercion of EvenArrayRef'
    );

    is_deeply(
        $foo->arrayreftohashref([qw(j 11 k 10 l 9)]),
        { j => 11, k => 10, l => 9, },
        'coercion of ArrayRefToHashRef'
    );

    is_deeply(
        $foo->arrayreftohashkeys([qw(m n o)]),
        { m => undef, n => undef, o => undef, },
        'coercion of ArrayRefToHashKeys'
    );

    eval {
        require Regexp::Assemble;
    };
    if ($@) {
        is_deeply(
            $foo->arrayreftoregexpref([qw(foo bar baz)]),
            qr{foo|bar|baz},
            'coercion of ArrayRefToRegexpRef via homebrew regexp',
        );
    }
    else {
        is_deeply(
            $foo->arrayreftoregexpref([qw(foo bar baz)]),
            qr{(?:ba[rz]|foo)},
            'coercion of ArrayRefToRegexpRef via Regexp::Assemble',
        );
    }
}

__END__
