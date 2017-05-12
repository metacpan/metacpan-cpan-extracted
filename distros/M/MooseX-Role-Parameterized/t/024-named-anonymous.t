use strict;
use warnings;
use Test::More;

{
    package Test::Role;
    use MooseX::Role::Parameterized;

    parameter default_beer => (
        isa => "Str",
        is  => "ro",
        required => 1,
    );

    role {
        my $p = shift;

        has beer => (
            isa => "Str",
            is  => "ro",
            default => $p->default_beer,
        );
    };

    package Test::Class;
    use Moose;

    with 'Test::Role' => { default_beer => "O'Doul's" };

    package Test::Class2;
    use Moose;

    with 'Test::Role' => { default_beer => "Root" };

}

like(
    ($_->new->meta->calculate_all_roles)[0]->name,
    qr/\ATest::Role::__ANON__::SERIAL::[0-9]+\z/,
    "Right looking role name for $_",
) for qw( Test::Class Test::Class2 );

isnt(
    (Test::Class->new->meta->calculate_all_roles)[0]->name,
    (Test::Class2->new->meta->calculate_all_roles)[0]->name,
    'role names are unique'
);

done_testing;
