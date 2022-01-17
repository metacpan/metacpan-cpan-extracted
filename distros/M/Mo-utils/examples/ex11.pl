#!/usr/bin/env perl

use strict;
use warnings;

use Test::MockObject;

$Error::Pure::TYPE = 'Error';

use Mo::utils qw(check_number_of_items);

# Item object #1.
my $item1 = Test::MockObject->new;
$item1->mock('value', sub {
	return 'value1',
});

# Item object #1.
my $item2 = Test::MockObject->new;
$item2->mock('value', sub {
	return 'value2',
});

# Tested object.
my $self = Test::MockObject->new({
	'key' => [],
});
$self->mock('list', sub {
	return [
		$item1,
		$item2,
	];
});

# Check number of items.
check_number_of_items($self, 'list', 'value', 'Test', 'Item');

# Print out.
print "ok\n";

# Output like:
# ok