BEGIN
{
	require Config;
	if ($Config::Config{'useithreads'})
	{
		require threads;
		threads->import();
		require threads::shared;
		threads::shared->import();
	} else
	{
		require forks;
		forks->import();
		require forks::shared;
		forks::shared->import();
	}
}
use strict;
use warnings;

use Test::More tests => 11;


require_ok('Object::Base');


package Foo;
use Object::Base;
attributes ':shared', 'attr1', 'attr2';


package Bar;
use Object::Base 'Foo';
attributes ':shared' => undef, 'attr1' => undef, ':lazy';


package main;

my $foo = new_ok('Foo');
isa_ok($foo, 'Object::Base');
ok(is_shared($foo), '$foo is shared');

$foo->attr1 = 5;
$foo->attr1++;
is($foo->attr1, 6, '$foo->attr1 is 6');

$foo->attr2({ key1 => 'val1' });
ok($foo->attr2->{key1} eq 'val1', '$foo->attr2->{key1} is val1');

my $bar = new_ok('Bar');
isa_ok($bar, 'Foo');
ok(!is_shared($bar), '$bar not is shared');

$bar->attr2 = 19;
$bar->attr2--;
is($bar->attr2, 18, '$bar->attr2 is 18');

eval { $bar->attr1 = 4 };
ok($@, '$bar->attr1 removed');
