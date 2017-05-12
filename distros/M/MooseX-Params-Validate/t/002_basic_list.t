## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Roles::Blah;
    use Moose::Role;

    requires 'foo';
    requires 'bar';
    requires 'baz';

    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params::Validate;

    with 'Roles::Blah';

    sub foo {
        my ( $self, $bar ) = validated_list(
            \@_,
            bar => { isa => 'Str', default => 'Moose' },
        );
        return "Horray for $bar!";
    }

    sub bar {
        my $self = shift;
        my ( $foo, $baz ) = validated_list(
            \@_,
            foo => { isa => 'Foo' },
            baz => { isa => 'ArrayRef | HashRef', optional => 1 },
        );
        [ $foo, $baz ];
    }

    sub baz {
        my $self = shift;
        my ( $foo, $bar, $boo ) = validated_list(
            \@_,
            foo => {
                isa      => subtype( 'Object' => where { $_->isa('Foo') } ),
                optional => 1
            },
            bar => { does => 'Roles::Blah', optional => 1 },
            boo => {
                does     => role_type('Roles::Blah'),
                optional => 1
            },
        );
        return $foo || $bar || $boo;
    }
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo' );

is( $foo->foo, 'Horray for Moose!', '... got the right return value' );
is(
    $foo->foo( bar => 'Rolsky' ), 'Horray for Rolsky!',
    '... got the right return value'
);

is( $foo->baz( foo => $foo ), $foo, '... foo param must be a Foo instance' );

like(
    exception { $foo->baz( foo => 10 ) },
    qr/\QThe 'foo' parameter/,
    '... the foo param in &baz must be a Foo instance'
);
like(
    exception { $foo->baz( foo => 'foo' ) },
    qr/\QThe 'foo' parameter/,
    '... the foo param in &baz must be a Foo instance'
);
like(
    exception { $foo->baz( foo => [] ) },
    qr/\QThe 'foo' parameter/,
    '... the foo param in &baz must be a Foo instance'
);

is( $foo->baz( bar => $foo ), $foo, '... bar param must do Roles::Blah' );

like(
    exception { $foo->baz( bar => 10 ) },
    qr/\QThe 'bar' parameter/,
    '... the bar param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( bar => 'foo' ) },
    qr/\QThe 'bar' parameter/,
    '... the bar param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( bar => [] ) },
    qr/\QThe 'bar' parameter/,
    '... the bar param in &baz must be do Roles::Blah'
);

is( $foo->baz( boo => $foo ), $foo, '... boo param must do Roles::Blah' );

like(
    exception { $foo->baz( boo => 10 ) },
    qr/\QThe 'boo' parameter/,
    '... the boo param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( boo => 'foo' ) },
    qr/\QThe 'boo' parameter/,
    '... the boo param in &baz must be do Roles::Blah'
);
like(
    exception { $foo->baz( boo => [] ) },
    qr/\QThe 'boo' parameter/,
    '... the boo param in &baz must be do Roles::Blah'
);

like(
    exception { $foo->bar },
    qr/\QMandatory parameter 'foo'/,
    '... bar has a required param'
);
like(
    exception { $foo->bar( foo => 10 ) },
    qr/\QThe 'foo' parameter/,
    '... the foo param in &bar must be a Foo instance'
);
like(
    exception { $foo->bar( foo => 'foo' ) },
    qr/\QThe 'foo' parameter/,
    '... the foo param in &bar must be a Foo instance'
);
like(
    exception { $foo->bar( foo => [] ) },
    qr/\QThe 'foo' parameter/,
    '... the foo param in &bar must be a Foo instance'
);
like(
    exception { $foo->bar( baz => [] ) },
    qr/\QMandatory parameter 'foo'/,
    '.. the foo param is mandatory'
);

is_deeply(
    $foo->bar( foo => $foo ),
    [ $foo, undef ],
    '... the foo param in &bar got a Foo instance'
);

is_deeply(
    $foo->bar( foo => $foo, baz => [] ),
    [ $foo, [] ],
    '... the foo param and baz param in &bar got a correct args'
);

is_deeply(
    $foo->bar( foo => $foo, baz => {} ),
    [ $foo, {} ],
    '... the foo param and baz param in &bar got a correct args'
);

like(
    exception { $foo->bar( foo => $foo, baz => undef ) },
    qr/\QThe 'baz' parameter/,
    '... baz requires a ArrayRef | HashRef'
);
like(
    exception { $foo->bar( foo => $foo, baz => 10 ) },
    qr/\QThe 'baz' parameter/,
    '... baz requires a ArrayRef | HashRef'
);
like(
    exception { $foo->bar( foo => $foo, baz => 'Foo' ) },
    qr/\QThe 'baz' parameter/,
    '... baz requires a ArrayRef | HashRef'
);

my $var = 42;
like(
    exception { $foo->bar( foo => $foo, baz => $var ) },
    qr/\QThe 'baz' parameter/, '... baz requires a ArrayRef | HashRef'
);

done_testing();
