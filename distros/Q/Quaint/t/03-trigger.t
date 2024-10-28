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

	1;
}

my $odea = Odea->new();

is($odea->one, 'testing_testing');

is($odea->one('okay'), 'okay_testing');

$odea = Odea::Ex->new();

is($odea->one, 'testing_testing');

is($odea->one('okay'), 'okay_testing');

done_testing();
