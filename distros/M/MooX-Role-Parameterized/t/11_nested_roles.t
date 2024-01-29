use strict;
use warnings;
use Test::More;

{

    package Some::Role::A;

    use Moo::Role;
    use MooX::Role::Parameterized;

    role {
        my ( $params, $mop ) = @_;

        $mop->has( $params->{attr} => ( is => 'rw' ) );

        $mop->requires( $params->{requires} );
    };

    1;
}

{

    package Some::Role::B;

    use Moo::Role;
    use MooX::Role::Parameterized;

    role {
        my ( $params, $mop ) = @_;

        $mop->has( $params->{another_attr} => ( is => 'rw' ) );

        $mop->requires( $params->{another_requires} );

        $mop->with(
            'Some::Role::A' => {
                attr     => $params->{attr},
                requires => $params->{requires},
            }
        );

        $mop->meta->make_immutable;    # nop
    };

    sub xxx { }

    1;
}

{

    package Some::Class::C;

    use Moo;
    use MooX::Role::Parameterized::With;

    with "Some::Role::B" => {
        attr             => 'foo',
        requires         => 'yyy',
        another_attr     => 'bar',
        another_requires => 'xxx',
    };

    sub yyy { }

    1;
}

my $obj = Some::Class::C->new( foo => 1, bar => 2 );

isa_ok $obj, 'Some::Class::C';
is $obj->foo, 1, "parametric attr 'foo' should return 1";
is $obj->bar, 2, "parametric attr 'bar' should return 2";
ok $obj->DOES('Some::Role::A'), "should does role 'Some::Role::A'";
ok $obj->DOES('Some::Role::B'), "should does role 'Some::Role::B'";
can_ok $obj, 'xxx', 'yyy';

done_testing;
