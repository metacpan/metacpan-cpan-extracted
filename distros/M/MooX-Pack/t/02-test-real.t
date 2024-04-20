use strict;
use warnings;

use lib 't/lib';

use Test::More;

use Packme::Test;

my $original_string =  [
    'Date      |Description                |Income ', 
    'Robert              |Acock               |32 ', 
];

my $test = Packme::Test->new(raw_data => join "\n", @{ $original_string });

$test->unpack;

is_deeply($test->data, [
	{
		data => 'Date',
		description => 'Description',
		income => 'Income'
	},
	{
		'first name' => 'Robert',
		'last name' => 'Acock',
		'age' => '32'
	}
], "data is set");

$test->pack;

is($test->raw_data, join "\n", @{$original_string}); 

done_testing();
