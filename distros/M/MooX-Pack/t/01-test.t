use strict;
use warnings;

use lib 't/lib';

use Test::More;

use Packme::Test2;

my $original_string =  [
    'Date      |Description                |Income ', 
    'Dates     |Descriptions               |Incomes', 
];

my $test = Packme::Test2->new(raw_data => join "\n", @{ $original_string });

use Data::Dumper;

$test->unpack;

is_deeply($test->data, [
	{
		data => 'Date',
		description => 'Description',
		income => 'Income'
	},
	{
		data => 'Dates',
		description => 'Descriptions',
		notes => 'Incomes'
	}
], "data is set");

$test->pack;

is($test->raw_data, join "\n", @{$original_string}); 

done_testing();
