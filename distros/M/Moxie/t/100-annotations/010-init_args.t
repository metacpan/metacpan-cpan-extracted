#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

=pod

This test

=cut

{
    package Foo::NoArgs;
    use Moxie;

    extends 'Moxie::Object';

    has foo => sub { 'foo' };

    sub BUILDARGS : strict;
}

{
    package Foo::AssignSlot;
    use Moxie;

    extends 'Moxie::Object';

    has foo => sub { 'foo' };

    sub BUILDARGS : strict( foo => 'foo' );
}

{
    package Foo::CustomArg;
    use Moxie;

    extends 'Moxie::Object';

    has foo => sub { 'foo' };
    has bar => sub { 'bar' };

    sub BUILDARGS : strict(
        bar => 'foo',
        foo => 'bar',
    );
}

{
    package Foo::OptionalArg;
    use Moxie;

    extends 'Moxie::Object';

    has foo => sub { 'foo' };
    has bar => sub { 'bar' };

    sub BUILDARGS : strict(
        bar  => 'bar',
        foo? => 'foo',
    );
}

subtest '... NoArgs' => sub {
    my $foo;
    is(exception { $foo = Foo::NoArgs->new }, undef, '... no exception');
    isa_ok($foo, 'Foo::NoArgs');

    is($foo->{foo}, 'foo', '... got the expected default');

    {
        like(
            exception { Foo::NoArgs->new( foo => 10 ) },
            qr/^Constructor for \(Foo\:\:NoArgs\) expected 0 arguments, got \(2\)/,
            '... got the expected exception (`foo` is not accepted)'
        );

        like(
            exception { Foo::NoArgs->new( bar => 10 ) },
            qr/^Constructor for \(Foo\:\:NoArgs\) expected 0 arguments, got \(2\)/,
            '... got the expected exception (no arguments are accepted)'
        );

        like(
            exception { Foo::NoArgs->new( bar => 10, foo => 100 ) },
            qr/^Constructor for \(Foo\:\:NoArgs\) expected 0 arguments, got \(4\)/,
            '... got the expected exception (`foo` and other arguments are not accepted)'
        );

        like(
            exception { Foo::NoArgs->new( bar => 10, foo => 100, baz => 1000 ) },
            qr/^Constructor for \(Foo\:\:NoArgs\) expected 0 arguments, got \(6\)/,
            '... got the expected exception (nothing is accepted, seriously people)'
        );
    }
};

subtest '... AssignSlot' => sub {
    my $foo;
    is(exception { $foo = Foo::AssignSlot->new( foo => 10 ) }, undef, '... no exception');
    isa_ok($foo, 'Foo::AssignSlot');

    is($foo->{foo}, 10, '... got the expected slot');

    {
        like(
            exception { Foo::AssignSlot->new },
            qr/Constructor for \(Foo\:\:AssignSlot\) expected 2 arguments, got \(0\)/,
            '... got the expected exception (the `foo` param is required)'
        );

        like(
            exception { Foo::AssignSlot->new( bar => 10, baz => 1000 ) },
            qr/Constructor for \(Foo\:\:AssignSlot\) expected 2 arguments, got \(4\)/,
            '... got the expected exception (the `foo` param is (still) required)'
        );

        like(
            exception { Foo::AssignSlot->new( bar => 10, foo => 1000 ) },
            qr/Constructor for \(Foo\:\:AssignSlot\) expected 2 arguments, got \(4\)/,
            '... got the expected exception (the `foo` param must be alone)'
        );

        like(
            exception { Foo::AssignSlot->new( bar => 10 ) },
            qr/Constructor for \(Foo\:\:AssignSlot\) missing \(`foo`\) parameters, got \(`bar`\), expected \(`foo`\)/,
            '... got the expected exception (right arity, wrote param)'
        );
    }
};

subtest '... CustomArg' => sub {
    my $foo;
    is(exception { $foo = Foo::CustomArg->new( bar => 10, foo => 20 ) }, undef, '... no exception');
    isa_ok($foo, 'Foo::CustomArg');

    is($foo->{foo}, 10, '... got the expected slot');
    is($foo->{bar}, 20, '... got the expected slot');

    {
        like(
            exception { Foo::CustomArg->new },
            qr/Constructor for \(Foo\:\:CustomArg\) expected 4 arguments, got \(0\)/,
            '... got the expected exception (must supply arguments)'
        );

        like(
            exception { Foo::CustomArg->new( foo => 200 ) },
            qr/Constructor for \(Foo\:\:CustomArg\) expected 4 arguments, got \(2\)/,
            '... got the expected exception (must supply (both) arguments)'
        );

        like(
            exception { Foo::CustomArg->new( foo => 200, bar => 300, baz => 400 ) },
            qr/Constructor for \(Foo\:\:CustomArg\) expected 4 arguments, got \(6\)/,
            '... got the expected exception (must supply only the required arguments)'
        );

        like(
            exception { Foo::CustomArg->new( foo => 10, baz => 100 ) },
            qr/Constructor for \(Foo\:\:CustomArg\) missing \(`bar`\) parameters, got \(`baz`\, `foo`\), expected \(`bar`\, `foo`\)/,
            '... got the expected exception (right arity, wrong params)'
        );

        like(
            exception { Foo::CustomArg->new( bar => 10, baz => 100 ) },
            qr/Constructor for \(Foo\:\:CustomArg\) missing \(`foo`\) parameters, got \(`bar`\, `baz`\), expected \(`bar`\, `foo`\)/,
            '... got the expected exception (right arity, wrong params)'
        );

    }
};

subtest '... OptionalArg' => sub {
    {
        my $foo;
        is(exception { $foo = Foo::OptionalArg->new( bar => 10, foo => 20 ) }, undef, '... no exception');
        isa_ok($foo, 'Foo::OptionalArg');

        is($foo->{foo}, 20, '... got the expected slot');
        is($foo->{bar}, 10, '... got the expected slot');
    }

    {
        my $foo;
        is(exception { $foo = Foo::OptionalArg->new( bar => 10 ) }, undef, '... no exception');
        isa_ok($foo, 'Foo::OptionalArg');

        is($foo->{foo}, 'foo', '... got the expected slot');
        is($foo->{bar}, 10, '... got the expected slot');
    }

    {
        like(
            exception { Foo::OptionalArg->new },
            qr/Constructor for \(Foo\:\:OptionalArg\) expected between 2 and 4 arguments, got \(0\)/,
            '... got the expected exception (must supply arguments)'
        );

        like(
            exception { Foo::OptionalArg->new( foo => 200 ) },
            qr/Constructor for \(Foo\:\:OptionalArg\) missing \(`bar`\) parameters, got \(`foo`\)\, expected \(`bar`\, `foo\?`\)/,
            '... got the expected exception (must supply (both) arguments)'
        );

        like(
            exception { Foo::OptionalArg->new( foo => 200, bar => 300, baz => 400 ) },
            qr/Constructor for \(Foo\:\:OptionalArg\) expected between 2 and 4 arguments, got \(6\)/,
            '... got the expected exception (must supply only the required arguments)'
        );

        like(
            exception { Foo::OptionalArg->new( foo => 10, baz => 100 ) },
            qr/Constructor for \(Foo\:\:OptionalArg\) missing \(`bar`\) parameters, got \(`baz`\, `foo`\)\, expected \(`bar`\, `foo\?`\)/,
            '... got the expected exception (right arity, wrong params)'
        );

        like(
            exception { Foo::OptionalArg->new( bar => 10, baz => 100 ) },
            qr/Constructor for \(Foo\:\:OptionalArg\) got unrecognized parameters \(`baz`\)/,
            '... got the expected exception (right arity, unrecognized param)'
        );

    }
};

done_testing;

