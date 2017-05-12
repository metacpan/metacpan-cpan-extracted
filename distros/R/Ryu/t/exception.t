use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use Ryu::Exception;

subtest 'Basic exceptions' => sub {
	my $ex = new_ok('Ryu::Exception', [
		message => 'failure',
		type => 'generic',
		details => [],
	]);

	is($ex->message, 'failure', 'message is correct');
	is($ex->type, 'generic', 'type is correct');
	done_testing;
};

subtest 'Future handling' => sub {
	my $ex = new_ok('Ryu::Exception', [
		message => 'failure that should be applied to a Future',
		type => 'generic',
		details => [qw(no details)],
	]);
	my $f = Future->new;
	is(exception {
		is($ex->fail($f), $f, '->fail returns the Future it was passed');
	}, undef, 'can ->fail without errors');
	ok($f->is_ready, '$f is ready');
	ok(!$f->is_done, '... and not done');
	ok(!$f->is_cancelled, '... or cancelled');
	cmp_deeply([ $f->failure ], [
		$ex->message,
		$ex->type => $ex->details
	], 'failure is correct');
	my $ex2 = Ryu::Exception->from_future($f);
	is($ex->$_, $ex2->$_, "$_ matches when reconstructing from Future") for qw(message type);
	cmp_deeply([ $ex->details ], [ $ex2->details ], "details match when reconstructing from Future");
};

done_testing;


