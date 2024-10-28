use Test::More;

{
	package Odea;

	use Quaint;

	any ro "one";

	bool "two";

	str default {
		"testing"
	} "three";

	num default {
		100
	} "four";

	array default { [
		qw/one two three/
	] } "five";

	hash default { {
		one => 1,
		two => 2,
		three => 3
	} } 'six';

	obj default { 
		bless {}, 'Foo';
	} 'seven';
	
	1;
}

{
	package Odea::Ex;

	use Quaint;
	
	extends 'Odea';

	any ro "eleven";

	1;
}

my $odea = Odea->new(one => 1, two => 1);

is($odea->one, 1);

is($odea->two, 1);

$odea->two(0);

is($odea->two, 0);

is($odea->three, 'testing');

is($odea->four, 100);

is_deeply($odea->five, [qw/one two three/]);

is_deeply($odea->six, {one => 1, two => 2, three => 3});

is( ref $odea->seven, 'Foo'); 

$odea = Odea::Ex->new(one => 1, two => 1);

is($odea->one, 1);

is($odea->two, 1);

$odea->two(0);

is($odea->two, 0);

is($odea->three, 'testing');

is($odea->four, 100);

is_deeply($odea->five, [qw/one two three/]);

is_deeply($odea->six, {one => 1, two => 2, three => 3});

is( ref $odea->seven, 'Foo'); 

done_testing();
