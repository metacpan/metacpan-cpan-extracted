use Test::More;
BEGIN {
    eval q{ require Moose; Moose->VERSION("2.00"); require Moo; Moo->VERSION("1.000000"); 1 }
        or plan skip_all => "need Moose and Moo";
    plan tests => 14;
};

{
    package Local::Role1;
    use Moose::Role;
    sub foo1 { 1 };
}

{
    package Local::Role2;
    use Moo::Role;
    sub foo2 { 2 };
}

{
    package Local::Role3;
    use Role::Tiny;
    sub foo3 { 3 };
}

{
    package Local::Class;
    use Moos;
    has 'bar';
    with qw(
        Local::Role1
        Local::Role2
        Local::Role3
    );
}

can_ok 'Local::Class', qw( new foo1 foo2 foo3 bar );
my $obj = new_ok 'Local::Class', [ bar => 42 ];

is($obj->foo1, 1);
is($obj->foo2, 2);
is($obj->foo3, 3);
is($obj->bar, 42);

ok('Local::Class'->DOES('Local::Class'));
ok('Local::Class'->DOES('Local::Role1'));
ok('Local::Class'->DOES('Local::Role2'));
ok('Local::Class'->DOES('Local::Role3'));
ok(not 'Local::Class'->does('Local::Class'));
ok('Local::Class'->does('Local::Role1'));
ok('Local::Class'->does('Local::Role2'));
ok('Local::Class'->does('Local::Role3'));
