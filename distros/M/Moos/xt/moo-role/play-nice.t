use Test::More;
BEGIN {
    eval q{ require Moo; Moo->VERSION("1.000000"); 1 }
        or plan skip_all => "need Moo";
    plan tests => 6;
};

{
    package Local::Role;
    use Moo::Role;
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
    Local::Class->does('Local::Role'),
);

ok(
    Local::Class->DOES('Local::Role'),
);
