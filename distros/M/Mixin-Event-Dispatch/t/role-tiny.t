use strict;
use warnings;

use Test::More;

BEGIN {
	eval {
		require Role::Tiny;
	} or do {
		plan skip_all => 'needs Role::Tiny';
	};
}

{
	package Local::Some::Role;
	use Role::Tiny;
	use Mixin::Event::Dispatch::Methods qw(:all);
}

{
	package Local::Some::Class;
	use Role::Tiny::With;
	with 'Local::Some::Role';
	sub new { my $class = shift; bless { @_ }, $class }
}

my $obj = Local::Some::Class->new;
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

done_testing;


