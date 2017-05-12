use Test::More tests => 7;

my %before;

BEGIN {
	package Local::Role1; no thanks;
	use MooseX::RoleQR;
	
	before qr{^b} => sub {
		$before{ $_[1] }++;
	};
}

BEGIN {
	package Local::Role2; no thanks;
	use Moose::Role;
	with qw( Local::Role1 );
	sub bumf { 1 };
};

BEGIN {
	package Local::Class1; no thanks;
	use Moose;
	with qw( Local::Role1 );
	sub foo1 { 1 };
	sub bar1 { 1 };
	sub baz1 { 1 };
};

BEGIN {
	package Local::Class2; no thanks;
	use Moose;
	with qw( Local::Role2 );
	sub foo2 { 1 };
	sub bar2 { 1 };
	sub baz2 { 1 };
};

Local::Class1->foo1('foo1');   ok !$before{'foo1'};
Local::Class1->bar1('bar1');   ok  $before{'bar1'};
Local::Class1->baz1('baz1');   ok  $before{'baz1'};
Local::Class2->foo2('foo2');   ok !$before{'foo2'};
Local::Class2->bar2('bar2');   ok  $before{'bar2'};
Local::Class2->baz2('baz2');   ok  $before{'baz2'};
Local::Class2->bumf('bumf');   ok  $before{'bumf'};
