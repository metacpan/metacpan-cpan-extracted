## no critic (Moose::RequireCleanNamespace, Modules::ProhibitMultiplePackages, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::More;

{
    package Foo;

    use Moose;
    use MooseX::Params::Validate;
    use overload (
        qw{""} => 'to_string',
    );

    has 'id' => (
        is      => 'ro',
        isa     => 'Str',
        default => '1.10.100',
    );

    sub to_string {
        my ( $self, %args ) = validated_hash(
            \@_,
            padded => {
                isa      => 'Bool',
                optional => 1,
                default  => 0,
            },
        );

        # 1.10.100 => 0001.0010.0100
        my $id
            = $args{padded}
            ? join(
            '.',
            map { sprintf( '%04d', $_ ) } split( /\./, $self->id )
            )
            : $self->id;

        return $id;
    }
}

isa_ok( my $foo = Foo->new(), 'Foo', 'new' );

is( $foo->id, '1.10.100', 'id' );

is( $foo->to_string, '1.10.100', 'to_string' );

is(
    $foo->to_string( padded => 1 ), '0001.0010.0100',
    'to_string( padded => 1 )'
);

done_testing();
