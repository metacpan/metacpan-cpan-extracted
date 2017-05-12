use Perl6::Form qw(form drill);

@data = (
	{item => 'food', cost => 100.23 },
	{item => 'wine, MOTASes, and song', cost => 32158 },
	{item => 'cars', cost => 0.2 },
);

my ($item, $cost) = drill(@data, [], [qw{item cost}]);

print form
	 "Item                         Cost",
	 {under=>"_"},
	 '{]]]]]]]]]]]]]]]]]]]]]]]}    {$] ]]].[}',
	 $item,						   {rfill=>0},
								   $cost;
