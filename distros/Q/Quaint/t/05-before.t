use Test::More;

{
	package Odea;

	use Quaint;

	any default {
		"testing"
	} trigger { 
		$_[1] . '_testing'
	}  "one";
	
	1;
}

{
	package Odea::Ex;

	use Quaint;
	
	extends 'Odea';

	any "two", "three";

	before {
		$_[0]->two(22);
	} "one";

	after {
		$_[0]->three(33);
	} "one";

	around {
		return $_[1];	
	} "one";


	function { 
		return $_[1];
	} "four";

	before {
		$_[0]->two(44);
	} after {
		$_[0]->three(66);
	} around {
		return 'testing_' . $_[1];
	} "four";

	1;
}

my $odea = Odea->new();

is($odea->one, 'testing_testing');

is($odea->one('okay'), 'okay_testing');

my $odea = Odea::Ex->new();

is($odea->one, 'testing_testing');

is($odea->two, 22);

is($odea->one('okay'), 'okay_testing');

is($odea->three, 33);

is($odea->four("update"), "testing_update");

is($odea->two, 44);

is($odea->three, 66);

done_testing();
