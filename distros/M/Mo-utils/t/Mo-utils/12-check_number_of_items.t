use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_number_of_items);
use Test::MockObject;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $self = Test::MockObject->new({
	'key' => [],
});
my $item1 = Test::MockObject->new;
$item1->mock('method', sub {
	return 'item1',
});
my $item2 = Test::MockObject->new;
$item2->mock('method', sub {
	return 'item1',
});
$self->mock('list', sub {
	return [
		$item1,
		$item2,
	];
});
eval {
	check_number_of_items($self, 'list', 'method', 'Test', 'Item');
};
is($EVAL_ERROR, "Test for Item 'item1' has multiple values.\n",
	"Test for Item 'item1' has multiple values.");
clean();

# Test.
$self = Test::MockObject->new({
	'key' => [],
});
$item1 = Test::MockObject->new;
$item1->mock('method', sub {
	return 'item1',
});
$item2 = Test::MockObject->new;
$item2->mock('method', sub {
	return 'item2',
});
$self->mock('list', sub {
	return [
		$item1,
		$item2,
	];
});
my $ret = check_number_of_items($self, 'list', 'method', 'Test', 'Item');
is($ret, undef, 'For each key is one value.');
