use strict;
use warnings;
use Test::More 0.88 skip_all => "Not implemented yet";

{
    package Test::Role;
    use MooseX::Role::Parameterized;

    parameter name => (
        isa => "Str",
        is  => "ro",
        required => 1,
    );

    role {
        my $p = shift;

        method foo => sub { "hello " . $p->name };

        has blech => (
            isa => "Str",
            is  => "ro",
            required => 1,
        );
    };

    package Test::Consumer;
    use MooseX::Role::Parameterized -parameter_roles => [
        'Test::Role' => { name => "foo" },
    ];

    role {
        my $p = shift;

        method parameters => sub { $p };
    };

    package Test::Class;
    use Moose;

    with 'Test::Consumer' => { blech => "yes" };
}

my $obj = Test::Class->new;

does_ok( $obj, "Test::Consumer" );

can_ok( $obj, "parameters" );

my $p = $obj->parameters;

does_ok( $p, "Test::Role" );
can_ok( $p, "foo" );
can_ok( $p, "blech" );

is( $p->blech, "yes" );

is( $p->foo, "hello foo" );

done_testing;
