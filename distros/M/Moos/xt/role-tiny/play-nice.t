use Test::More;
BEGIN {
    eval q{ require Role::Tiny; Role::Tiny->VERSION("1.002000"); 1 }
        or plan skip_all => "need Role::Tiny";
    plan tests => 5;
};

{
    package Local::Role;
    use Role::Tiny;
    sub foo { 1 };
}

{
    package Local::Class;
    use Moos;
    has 'bar';
    with qw( Local::Role );
}

can_ok 'Local::Class', qw( new foo bar );
my $obj = new_ok 'Local::Class', [ bar => 42 ];

is($obj->foo, 1);
is($obj->bar, 42);

ok(
    Local::Class->DOES('Local::Role'),
);
