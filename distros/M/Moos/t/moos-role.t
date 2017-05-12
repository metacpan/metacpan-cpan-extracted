use strict;
use warnings;
use Test::More;

BEGIN {
    eval q{
        require Role::Tiny;
        require Class::Method::Modifiers;
        1;
    } or plan skip_all => "";
}

{
    package Local::Role1;
    use Moos-Role;

    has attr1 => (is => 'ro', clearer => 1);
    sub method1 { 1 };
    around method3 => sub { 42 };
}

{
    package Local::Role2;
    use Moos-Role;
    with qw( Local::Role1 );

    has attr2 => (is => 'ro', clearer => 1);
    sub method2 { 2 };
    around method3 => sub { 43 };
}

{
    package Local::Class;
    use Moos;
    with qw( Local::Role2 );

    has attr3 => (is => 'ro', clearer => 1);
    sub method2 { 22 };
    sub method3 { 3 };
}

my $obj = new_ok 'Local::Class' => [
    attr1 => 111,
    attr2 => 222,
    attr3 => 333,
];

can_ok $obj, qw(
    attr1 attr2 attr3
    clear_attr1 clear_attr2 clear_attr3
    method1 method2 method3
);

is($obj->attr1, 111);
is($obj->attr2, 222);
is($obj->attr3, 333);
is($obj->method1, 1);
is($obj->method2, 22);
is($obj->method3, 43);

done_testing();

