use strict;
use warnings;

use Test::More;

{
	package Local::test::all;
	use Mixin::Event::Dispatch::Methods qw(:all);

	sub new { my $class = shift; bless { @_ }, $class }
}

{
	package Local::test::basic;
	use Mixin::Event::Dispatch::Methods qw(:basic);

	sub new { my $class = shift; bless { @_ }, $class }
}

for my $class (qw(Local::test::all Local::test::basic)) {
	subtest $class => sub {
		my $obj = $class->new;
		my @expected = qw(x y z);
		my $called = 0;
		$obj->subscribe_to_event(
			my @ev = (
				test_event => sub {
					my ($ev, @args) = @_;
					is_deeply(\@args, \@expected, 'have expected args');
					++$called;
				}
			)
		);
		ok(!$called, 'not called yet');
		$obj->invoke_event(test_event => @expected);
		is($called, 1, 'called event handler');
		$obj->unsubscribe_from_event(@ev);
		$obj->invoke_event(test_event => @expected);
		is($called, 1, 'event handler not called after unsubscribe');
	}
}

done_testing;

