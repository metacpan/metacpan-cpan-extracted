use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';
{

    package FooWith;

    use Moo qw(has);
    use MooX::Role::Parameterized::With;

    with Bar => { attr => 'baz', method => 'run' };

    has foo => ( is => 'ro' );

    1;
}

subtest "FooWith" => sub {

    my $foo = FooWith->new( foo => 1, bar => 2, baz => 3 );

    isa_ok $foo, 'FooWith', 'foo';
    ok $foo->DOES('Bar'), 'foo should does Bar';
    is $foo->foo, 1, 'should has foo';
    is $foo->bar, 2, 'should has bar ( from Role )';
    is $foo->baz, 3, 'should has baz ( from parameterized Role)';
    can_ok( $foo, 'run' );
    is $foo->run, 1024, 'should call run';

    done_testing;
};

{

    package FooWith2;

    use Moo qw(has);
    use MooX::Role::Parameterized::With;

    with Bar => { attr => 'baz', method => 'run' },
      Bar    => { attr => 'bam', method => 'doit' };

    has foo => ( is => 'ro' );

    1;
}

subtest "FooWith2" => sub {

    my $foo = FooWith2->new( foo => 1, bar => 2, baz => 3, bam => 4 );

    isa_ok $foo, 'FooWith2', 'foo';
    ok $foo->DOES('Bar'), 'foo should does Bar';
    is $foo->foo, 1, 'should has foo';
    is $foo->bar, 2, 'should has bar ( from Role )';
    is $foo->baz, 3, 'should has baz ( from parameterized Role)';
    is $foo->bam, 4, 'should has bam ( from parameterized Role)';
    can_ok( $foo, 'run', 'doit' );
    is $foo->run,  1024, 'should call run';
    is $foo->doit, 1024, 'should call doit';

    done_testing;
};

{

    package FooWithArrayRef;

    use Moo qw(has);
    use MooX::Role::Parameterized::With;

    with Bar => [
        { attr => 'baz', method => 'run' },
        { attr => 'bam', method => 'doit' }
      ],
      Bar => { attr => 'bum', method => 'lol' };

    has foo => ( is => 'ro' );

    1;
}

subtest "FooWiFooWithArrayRefth2" => sub {

    my $foo =
      FooWithArrayRef->new( foo => 1, bar => 2, baz => 3, bam => 4, bum => 5 );

    isa_ok $foo, 'FooWithArrayRef', 'foo';
    ok $foo->DOES('Bar'), 'foo should does Bar';
    is $foo->foo, 1, 'should has foo';
    is $foo->bar, 2, 'should has bar ( from Role )';
    is $foo->baz, 3, 'should has baz ( from parameterized Role)';
    is $foo->bam, 4, 'should has bam ( from parameterized Role)';
    is $foo->bum, 5, 'should has bum ( from parameterized Role)';
    can_ok( $foo, 'run', 'doit', 'lol' );
    is $foo->run,  1024, 'should call run';
    is $foo->doit, 1024, 'should call doit';
    is $foo->lol,  1024, 'should call lol';

    done_testing;
};

{

    package Bar::RoleTiny;

    use Role::Tiny;

    around bar => sub {'not what you expects'};

    1;
}
{

    package Baz::MooRole;

    use Moo::Role;

    around baz => sub {'not what you expects too'};

    1;
}

{

    package FooWithRoleTiny;

    use Moo;
    use MooX::Role::Parameterized::With;

    with Bar => { attr => 'baz', method => 'run' }, "Bar::RoleTiny",
      "Baz::MooRole";

    has foo => ( is => 'ro' );

    1;
}

subtest "FooWithRoleTiny" => sub {

    my $foo = FooWithRoleTiny->new( foo => 1, baz => 3 );

    isa_ok $foo, 'FooWithRoleTiny', 'foo';
    ok $foo->DOES('Bar::RoleTiny'), 'foo should does Bar::RoleTiny';
    ok $foo->DOES('Baz::MooRole'),  'foo should does Baz::MooRole';

    is $foo->foo, 1,                          'should has foo';
    is $foo->bar, 'not what you expects',     'should has bar ( from Role )';
    is $foo->baz, 'not what you expects too', 'should has baz ( from Role)';
    can_ok( $foo, 'run' );
    is $foo->run, 1024, 'should call run';

    done_testing;

};

subtest "with should die with non role" => sub {
    throws_ok {

        {

            package Z::Z::Z;

            sub foo { }

            1;
        }
        {

            package X::Y::Z;

            use MooX::Role::Parameterized::With;

            with "Z::Z::Z";

            1;
        }

    }
    qr<Can't apply role to 'X::Y::Z' - 'Z::Z::Z' is neither a MooX::Role::Parameterized, Moo::Role or Role::Tiny role>,
      "should die if role is not an expected type";

    done_testing;
};

done_testing;
