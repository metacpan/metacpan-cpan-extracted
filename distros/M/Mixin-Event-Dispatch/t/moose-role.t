use strict;
use warnings;

use Test::More;

BEGIN {
	eval {
		require Moose;
		require MooseX::MarkAsMethods;
	} or do {
		plan skip_all => 'needs Moose + MooseX::MarkAsMethods';
	};
}

{
	package Local::Some::Role;
	use Moose::Role;
	use MooseX::MarkAsMethods;

	use Mixin::Event::Dispatch::Methods qw(:all);

	__PACKAGE__->meta->mark_as_method(
		@{ $Mixin::Event::Dispatch::Methods::EXPORT_TAGS{all} }
	);
}

{
	package Local::Some::Class;
	use Moose;
	with 'Local::Some::Role';
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


