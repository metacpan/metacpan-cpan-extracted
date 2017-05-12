use strict;
use warnings;

use Test::More;
use Test::Builder;
use Test::Builder::Clutch;

plan tests => 14;

ok(1, 'ok() works');

TODO: {
	local $TODO = 'TODO block works';
	fail 'abject failure';
}

subtest 'subtest works' => sub {
	plan tests => 2;
	pass;
	pass;
};

subtest 'failure in subtest disengaged' => sub {
	plan tests => 3;
	ok 1, 'abject pass';
	Test::Builder::Clutch->disengage;
	my $ok = ok undef;
	Test::Builder::Clutch->engage;
	ok !$ok, 'ok() returned false while clutch disengaged';
	ok 1, 'abject pass';
};

TODO: {
	local $TODO = 'subtest inside TODO';
	subtest 'subtest inside TODO works' => sub {
		plan tests => 2;
		pass;
		fail 'abject failure';
	};
}

TODO: {
	local $TODO = 'subtest inside subtest inside TODO';
	subtest 'subtest inside subtest inside TODO works' => sub {
		plan tests => 2;
		pass;
		subtest 'subtest inside TODO works' => sub {
			plan tests => 2;
			pass;
			fail 'abject failure';
		}
	};
}

Test::Builder::Clutch->disengage;
pass 'clutch is disengaged'; # DO NOT COUNT THIS TEST
Test::Builder::Clutch->engage;
pass 'clutch is engaged';
ok(Test::Builder->new->is_passing, 'test is still passing');

Test::Builder::Clutch->disengage;
fail 'clutch is disengaged'; # DO NOT COUNT THIS TEST
Test::Builder::Clutch->engage;
pass 'clutch is engaged';
ok(Test::Builder->new->is_passing,
   'test reports as passing when clutch engaged');
ok(Test::Builder->new->failed_while_disengaged,
	'failure while disengaged was recorded');
Test::Builder::Clutch->disengage;
my $ok = Test::Builder->new->is_passing;
Test::Builder::Clutch->engage;
ok !$ok, 'test reports as not passing when clutch disengaged';


my $Test = Test::Builder->new;

TODO: {
	local $TODO = 'Test::Builder failures inside TODO';

	$Test->ok(0, 'abject failure');

	$Test->subtest('Test::Builder->subtest with failures' => sub {
		$Test->plan(tests => 2);
		$Test->ok(1);
		$Test->ok(0, 'abject failure');
	});
}

