use Test::More tests => 5;

# -----------------------------------------------

BEGIN{ use_ok('Search::InvertedIndex::Simple::BerkeleyDB'); }

# -----------------------------------------------

sub trial
{
	my($db, $expectation, $key) = @_;
	my($value) = $db -> db_get($key);
	my($set)   = $db -> inflate($value);

	#diag "Data:        ", join(', ', map{"$_ => $$key{$_}"} sort keys %$key), ". \n";
	#diag "db_get:      ", join(', ', map{"$_ => $$value{$_}"} sort keys %$value), ". \n";
	#diag "Expectation: $expectation. \n";
	#diag "Result:      ", $set ? join(',', $set -> print() ) : 'Search did not find any matching records', ". \n";
	#diag "\n";

	is($expectation, join(',', $set -> print() ), 'Test data: ' . join(', ', map{"$_ => $$key{$_}"} sort keys %$key) );

}	# End of trial.

# -----------------------------------------------

my($dataset) =
[
	{	# 0
		address        => 'Murrumbeena',
		department     => 'Programming',
		name           => 'Ron Savage',
		preferred_name => 'Ron',
		surname        => 'Savage',
	},
	{	# 1
		address        => 'Mooroopna',
		department     => 'Entertainment',
		name           => 'Zoe Savage',
		preferred_name => 'Zoe',
		surname        => 'Savage',
	},
	{	# 2
		address        => 'Mt Waverley',
		department     => 'Ecology',
		name           => 'Frances Savage',
		preferred_name => 'Fran',
		surname        => 'Smith',
	},
	{	# 3
		address        => 'Mt Waverley',
		department     => 'Publishing',
		name           => 'Violet Savage',
		preferred_name => 'Vi',
		surname        => 'Savage',
	},
	{	# 4
		address        => 'Murrwillumba',
		department     => 'Polyantics',
		name           => 'Zephyr Savage',
		preferred_name => 'Zef',
		surname        => 'Savage',
	},
];
my($keyset) = [qw/address department/];
my($db)     = Search::InvertedIndex::Simple::BerkeleyDB -> new(dataset => $dataset, keyset => $keyset);

$db -> db_put();

#diag map{"$_\n" } @{$db -> db_print()};
#diag "\n";

trial($db, '2', {address => 'Mt', department => 'Eco'});
trial($db, '0,4', {address => 'Mu', department => 'P'});

$dataset =
[
	{ # Index: 0.
		address => 'Here',
		event   => 'End',
		time    => 'Time',
	},
	{ # Index: 1.
		address => 'Heaven',
		event   => 'Exit',
		time    => 'Then',
	},
	{ # Index: 2.
		address => 'House',
		event   => 'Finish',
		time    => 'Thus',
	}
];
$keyset = [qw/address time/];
$db     = Search::InvertedIndex::Simple::BerkeleyDB -> new(dataset => $dataset, keyset => $keyset);

$db -> db_put();

#diag map{"$_\n" } @{$db -> db_print()};
#diag "\n";

trial($db, '1', {address => 'Hea', time => 'T'});
trial($db, '1,2', {address => 'H', time => 'Th'});
