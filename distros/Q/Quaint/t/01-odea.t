use Test::More;

{
	package Odea;

	use Quaint;

	any ro "one";

	any qw/two three/;

	any ro req qw/four/;

	any ro req default {
		"testing"
	} qw/five six/;

	any default {
		"testing"
	} ro req qw/seven eight/;

	any default {
		$_[0]->five . ' ' . $_[0]->seven;
	} qw/nine/;

	function {
		'okay';
	} "ten";

	1;
}

{
	package Odea::Ex;

	use Quaint;
	
	extends 'Odea';

	any ro "eleven";

}

my $odea = Odea->new(one => 1, two => 2, three => 3, four => 4);

is($odea->one, 1);

eval {
	$odea->one(11);
};

like($@, qr/attribute one is readonly/);

is($odea->two, 2);

ok($odea->two(22));

is($odea->two, 22);

is($odea->three, 3);

is($odea->four, 4);

is($odea->five, 'testing');

is($odea->six, 'testing');

is($odea->seven, 'testing');

is($odea->eight, 'testing');

is($odea->nine, 'testing testing');

is($odea->ten, 'okay');

eval {
	Odea->new(one => 1);
};

like($@, qr/attribute four is required/);

$odea = Odea::Ex->new(one => 1, two => 2, three => 3, four => 4);

is($odea->one, 1);

eval {
	$odea->one(11);
};

like($@, qr/attribute one is readonly/);

is($odea->two, 2);

ok($odea->two(22));

is($odea->two, 22);

is($odea->three, 3);

is($odea->four, 4);

is($odea->five, 'testing');

is($odea->six, 'testing');

is($odea->seven, 'testing');

is($odea->eight, 'testing');

is($odea->nine, 'testing testing');

is($odea->ten, 'okay');

eval {
	Odea::Ex->new(one => 1);
};

like($@, qr/attribute four is required/);

done_testing();
