## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Roles::Blah;
    use Moose::Role;
    use MooseX::Params::Validate;

    requires 'bar';
    requires 'baz';

    sub foo {
        my ( $self, %params ) = validated_hash(
            \@_,
            bar => { isa => 'Str', default => 'Moose' },
        );
        return "Horray for $params{bar}!";
    }

    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params::Validate;

    with 'Roles::Blah';

    sub bar {
        my $self = shift;
        return [
            pos_validated_list(
                \@_,
                { isa => 'Foo' },
                { isa => 'ArrayRef | HashRef', optional => 1 },
                { isa => 'ArrayRef[Int]', optional => 1 },
            )
        ];
    }

    sub baz {
        my $self = shift;
        return [
            pos_validated_list(
                \@_, {
                    isa => subtype( 'Object' => where { $_->isa('Foo') } ),
                    optional => 1
                },
                { does => 'Roles::Blah', optional => 1 },
                {
                    does     => role_type('Roles::Blah'),
                    optional => 1
                },
            )
        ];
    }
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo' );

is( $foo->baz($foo)->[0], $foo, '... first param must be a Foo instance' );

like(
    exception { $foo->baz(10) },
    qr/\QParameter #1/,
    '... the first param in &baz must be a Foo instance'
);
like(
    exception { $foo->baz('foo') },
    qr/\QParameter #1/,
    '... the first param in &baz must be a Foo instance'
);
like(
    exception { $foo->baz( [] ) },
    qr/\QParameter #1/,
    '... the first param in &baz must be a Foo instance'
);

is(
    $foo->baz( $foo, $foo )->[1], $foo,
    '... second param must do Roles::Blah'
);

like(
    exception { $foo->baz( $foo, 10 ) },
    qr/\QParameter #2/,
    '... the second param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( $foo, 'foo' ) },
    qr/\QParameter #2/,
    '... the second param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( $foo, [] ) },
    qr/\QParameter #2/,
    '... the second param in &baz must be do Roles::Blah'
);

is(
    $foo->baz( $foo, $foo, $foo )->[2], $foo,
    '... third param must do Roles::Blah'
);

like(
    exception { $foo->baz( $foo, $foo, 10 ) },
    qr/\QParameter #3/,
    '... the third param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( $foo, $foo, 'foo' ) },
    qr/\QParameter #3/,
    '... the third param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( $foo, $foo, [] ) },
    qr/\QParameter #3/,
    '... the third param in &baz must be do Roles::Blah'
);

like(
    exception { $foo->bar },
    qr/\Q0 parameters were passed/,
    '... bar has a required params'
);
like(
    exception { $foo->bar(10) },
    qr/\QParameter #1/,
    '... the first param in &bar must be a Foo instance'
);
like(
    exception { $foo->bar('foo') },
    qr/\QParameter #1/,
    '... the first param in &bar must be a Foo instance'
);
like(
    exception { $foo->bar( [] ) },
    qr/\QParameter #1/,
    '... the first param in &bar must be a Foo instance'
);
like(
    exception { $foo->bar() },
    qr/\Q0 parameters were passed/,
    '... bar has a required first param'
);

is_deeply(
    $foo->bar($foo),
    [$foo],
    '... the first param in &bar got a Foo instance'
);

is_deeply(
    $foo->bar( $foo, [] ),
    [ $foo, [] ],
    '... the first and second param in &bar got correct args'
);

is_deeply(
    $foo->bar( $foo, {} ),
    [ $foo,          {} ],
    '... the first param and baz param in &bar got correct args'
);

like(
    exception { $foo->bar( $foo, undef ) },
    qr/\QParameter #2/,
    '... second param requires a ArrayRef | HashRef'
);
like(
    exception { $foo->bar( $foo, 10 ) },
    qr/\QParameter #2/,
    '... second param requires a ArrayRef | HashRef'
);
like(
    exception { $foo->bar( $foo, 'Foo' ) },
    qr/\QParameter #2/,
    '... second param requires a ArrayRef | HashRef'
);
like(
    exception { $foo->bar( $foo, \( my $var ) ) },
    qr/\QParameter #2/,
    '... second param requires a ArrayRef | HashRef'
);

is_deeply(
    $foo->bar( $foo, {}, [ 1, 2, 3 ] ),
    [ $foo, {}, [ 1, 2, 3 ] ],
    '... the first param in &bar got a Foo instance'
);

like(
    exception { $foo->bar( $foo, {}, undef ) },
    qr/\QParameter #3/,
    '... third param a ArrayRef[Int]'
);
like(
    exception { $foo->bar( $foo, {}, 10 ) },
    qr/\QParameter #3/,
    '... third param a ArrayRef[Int]'
);
like(
    exception { $foo->bar( $foo, {}, 'Foo' ) },
    qr/\QParameter #3/,
    '... third param a ArrayRef[Int]'
);
like(
    exception { $foo->bar( $foo, {}, \( my $var ) ) },
    qr/\QParameter #3/,
    '... third param a ArrayRef[Int]'
);
like(
    exception { $foo->bar( $foo, {}, [qw/one two three/] ) },
    qr/\QParameter #3/, '... third param a ArrayRef[Int]'
);

done_testing();
