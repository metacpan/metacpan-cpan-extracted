use Test::More;

# Basic accessor_alias: replaces default function name
{
	package AliasBasic;
	use Object::Proto::Sugar;

	accessor_alias 'obj';

	has name => (is => 'rw', accessor => 1);
	has age  => (is => 'rw', accessor => 1);

	1;
}

my $obj = new AliasBasic 'Alice', 30;

# accessor => 1 with alias 'obj' installs obj_name, obj_age
is(AliasBasic::obj_name($obj), 'Alice', 'alias get name');
is(AliasBasic::obj_age($obj),  30,      'alias get age');

AliasBasic::obj_name($obj, 'Bob');
AliasBasic::obj_age($obj, 31);
is(AliasBasic::obj_name($obj), 'Bob', 'alias set name');
is(AliasBasic::obj_age($obj),  31,    'alias set age');

# method accessors still work
is($obj->name, 'Bob', 'method accessor still works');
is($obj->age,  31,    'method accessor still works');

# Custom accessor name is NOT affected by alias
{
	package AliasCustom;
	use Object::Proto::Sugar;

	accessor_alias 'get';

	has title => (is => 'rw', accessor => 'fetch_title');
	has value => (is => 'rw', accessor => 1);

	1;
}

my $ac = new AliasCustom 'Dr', 42;

is(AliasCustom::fetch_title($ac), 'Dr', 'custom accessor name unaffected by alias');
is(AliasCustom::get_value($ac),   42,   'accessor => 1 uses alias');

# reader/writer are NOT affected by alias
{
	package AliasRW;
	use Object::Proto::Sugar;

	accessor_alias 'x';

	has score => (is => 'rw', accessor => 1, reader => 1, writer => 1);

	1;
}

my $arw = new AliasRW 99;

is(AliasRW::x_score($arw),     99,  'aliased accessor works');
is(AliasRW::x_get_score($arw), 99,  'reader also aliased');
AliasRW::x_set_score($arw, 50);
is(AliasRW::x_score($arw),     50,  'aliased accessor after aliased writer');

# No alias: accessor => 1 still uses attribute name
{
	package NoAlias;
	use Object::Proto::Sugar;

	has color => (is => 'rw', accessor => 1);

	1;
}

my $na = new NoAlias 'red';
is(NoAlias::color($na), 'red', 'no alias uses attribute name');

# import_accessors imports aliased names - same class
{
	package AliasImportSelf;
	use Object::Proto::Sugar;

	accessor_alias 'si';

	has width  => (is => 'rw', accessor => 1);
	has height => (is => 'rw', accessor => 1);

	1;
}

AliasImportSelf->import_accessors;
my $si = new AliasImportSelf 10, 20;
is(si_width($si),  10, 'import_accessors: aliased width');
is(si_height($si), 20, 'import_accessors: aliased height');

# import_accessors with explicit aliased name across inheritance
{
	package AliasParent;
	use Object::Proto::Sugar;

	accessor_alias 'ap';

	has width  => (is => 'rw', accessor => 1);

	1;
}

{
	package AliasChild;
	use Object::Proto::Sugar;

	extends 'AliasParent';

	accessor_alias 'ac';

	has depth => (is => 'rw', accessor => 1);

	1;
}

my $child = new AliasChild 10, 5;

# import_accessors with explicit name
{
	package ExplicitImport;
	AliasChild->import_accessors('ac_depth');
	sub check { ac_depth($_[0]) }
}
is(ExplicitImport::check($child), 5, 'import_accessors: explicit aliased name');

{
	package ExplicitImportParent;
	AliasParent->import_accessors('ap_width');
	sub check { ap_width($_[0]) }
}
is(ExplicitImportParent::check($child), 10, 'import_accessors: explicit parent aliased name');

# accessor_alias with inheritance - child without alias inherits parent attrs
{
	package AliasBase;
	use Object::Proto::Sugar;

	accessor_alias 'b';

	has x => (is => 'rw', accessor => 1);

	1;
}

{
	package AliasNoAlias;
	use Object::Proto::Sugar;

	extends 'AliasBase';

	has y => (is => 'rw', accessor => 1);

	1;
}

my $na2 = new AliasNoAlias 1, 2;
is($na2->x, 1, 'inherited attr method works');
is($na2->y, 2, 'own attr method works');
is(AliasNoAlias::y($na2), 2, 'child without alias: accessor => 1 uses attr name');

# import from child where parent and child have different aliases
{
	package Vehicle;
	use Object::Proto::Sugar;

	accessor_alias 'v';

	has speed => (is => 'rw', accessor => 1);
	has fuel  => (is => 'rw', accessor => 1);

	1;
}

{
	package Car;
	use Object::Proto::Sugar;

	extends 'Vehicle';

	accessor_alias 'c';

	has brand => (is => 'rw', accessor => 1);
	has doors => (is => 'rw', accessor => 1);

	1;
}

Car->import_accessors;
my $car = new Car 120, 50, 'Toyota', 4;

# child's own accessors use child alias 'c'
is(c_brand($car), 'Toyota', 'import from child: child alias c_brand');
is(c_doors($car), 4,        'import from child: child alias c_doors');

# parent's accessors use parent alias 'v'
is(v_speed($car), 120, 'import from child: parent alias v_speed');
is(v_fuel($car),  50,  'import from child: parent alias v_fuel');

# set via aliased functions
c_brand($car, 'Honda');
v_speed($car, 200);
is(c_brand($car), 'Honda', 'import from child: set via c_brand');
is(v_speed($car), 200,     'import from child: set via v_speed');

done_testing();
