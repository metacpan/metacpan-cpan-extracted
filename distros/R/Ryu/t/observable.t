use strict;
use warnings;

use Test::More;

use Ryu::Observable;

subtest 'string and number handling' => sub {
	my $v = Ryu::Observable->new(123);
	is(0+$v, 123, 'number looks right');
	is("$v", "123", 'string looks right');
	done_testing;
};
subtest 'subscription' => sub {
	my $v = Ryu::Observable->new(123);
	my $expected = 124;
	my $called;
	$v->subscribe(sub {
		is($_, $_[0], 'value was passed in $_ and @_');
		is(shift, $expected, 'have expected value');
		++$called;
	});
	++$v;
	ok($called, 'callback was triggered');
	$v->set($expected = 65);
	is($called, 2, 'callback was triggered again');
	done_testing;
};

done_testing;


