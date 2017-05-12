use Test::More;
BEGIN {
    eval q{ require Moo; Moo->VERSION("1.000000"); 1 }
        or plan skip_all => "need Moo";
    plan tests => 10;
};

{
    package Local::Role;
    use Moo::Role;
    has 'x' => (documentation => 'XXX', is => 'ro');
    has 'y' => (documentation => 'YYY', is => 'ro');
}

{
    package Local::Class;
    use Moos;
    has 'z' => (documentation => 'ZZZ');
    with qw( Local::Role );
}

can_ok 'Local::Class', qw( new x y z );
my $obj = new_ok 'Local::Class', [ 'x' => 111, 'y' => 222, 'z' => 333 ];

is($obj->x, 111);
is($obj->y, 222);
is($obj->z, 333);

ok(
    Local::Class->does('Local::Role'),
);

ok(
    Local::Class->DOES('Local::Role'),
);

is($obj->meta->get_attribute('x')->documentation, 'XXX');
is($obj->meta->get_attribute('y')->documentation, 'YYY');
is($obj->meta->get_attribute('z')->documentation, 'ZZZ');

