use Test::More;
BEGIN {
    eval q{ require Moose; Moose->VERSION("2.00"); 1 }
        or plan skip_all => "need Moose";
    plan tests => 5;
};

{
    package Local::Role;
    use Moose::Role;
    sub foo { 1 };
}

{
    package Local::Class;
    use Moos;
    has 'bar';
    with 'Local::Role';
}

can_ok 'Local::Class', qw( new foo bar );
my $obj = new_ok 'Local::Class', [ bar => 42 ];

is($obj->foo, 1);
is($obj->bar, 42);

ok(
    'Local::Class'->DOES('Local::Role'),
);
