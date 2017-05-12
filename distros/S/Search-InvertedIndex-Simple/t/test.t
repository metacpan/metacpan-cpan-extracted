use Test::More tests => 4;

# -----------------------------------------------

BEGIN{ use_ok('Search::InvertedIndex::Simple'); }

# -----------------------------------------------

sub pwint
{
	my($index) = @_;

	my($primary_key, $secondary_key);

	for $primary_key (sort keys %$index)
	{
		for $secondary_key (sort keys %{$$index{$primary_key} })
		{
			print "Primary key: $primary_key. Secondary key: $secondary_key. ";
			print "Indexes into dataset: ", join(', ', $$index{$primary_key}{$secondary_key} -> print() ), ". \n";
		}

		print "\n";
	}

}	# End of pwint.

# -----------------------------------------------

sub trial
{
	my($test_id, $index, $primary_key_1, $primary_value_1, $primary_key_2, $primary_value_2, $expectation) = @_;

	#print "Intersection of: Primary key: $primary_key_1 = '$primary_value_1' with primary key: $primary_key_2 = '$primary_value_2': \n";
	#print "1st primary indexes:  ", join(', ', $$index{$primary_key_1}{$primary_value_1} -> print() ), ". \n";
	#print "2nd primary indexes:  ", join(', ', $$index{$primary_key_2}{$primary_value_2} -> print() ), ". \n";
	#print "Expected result:      $expectation. \n";
	#print "Intersection:         ", join(', ', $$index{$primary_key_1}{$primary_value_1} -> intersection($$index{$primary_key_2}{$primary_value_2}) ), ". \n";
	#print "\n";

	is(join(', ', $$index{$primary_key_1}{$primary_value_1} -> intersection($$index{$primary_key_2}{$primary_value_2}) ), $expectation, "Test id: $test_id");

}	# End of trial.

# -----------------------------------------------

my($dataset) =
[
	{	# 0
		address			=> 'Murrumbeena',
		department		=> 'Programming',
		name			=> 'Ron Savage',
		preferred_name	=> 'Ron',
		surname			=> 'Savage',
	},
	{	# 1
		address			=> 'Mooroopna',
		department		=> 'Entertainment',
		name			=> 'Zoe Savage',
		preferred_name	=> 'Zoe',
		surname			=> 'Savage',
	},
	{	# 2
		address			=> 'Mt Waverley',
		department		=> 'Economics',
		name			=> 'Frances Savage',
		preferred_name	=> 'Fran',
		surname			=> 'Smith',
	},
	{	# 3
		address			=> 'Mt Waverley',
		department		=> 'Publishing',
		name			=> 'Violet Savage',
		preferred_name	=> 'Vi',
		surname			=> 'Savage',
	},
	{	# 4
		address			=> 'Murrwillumba',
		department		=> 'Polyantics',
		name			=> 'Zephyr Savage',
		preferred_name	=> 'Zef',
		surname			=> 'Savage',
	},
];
my($keyset) = [qw/address department/];
my($index)	= Search::InvertedIndex::Simple -> new(dataset => $dataset, keyset => $keyset) -> build_index();

#pwint($index);

trial('one', $index, 'address', 'Mt', 'department', 'Eco', '2');
trial('two', $index, 'address', 'Mu', 'department', 'P',   '0, 4');

$dataset =
[
	{ # Index: 0.
		address => 'Here',
		event   => 'Start',
		time    => 'Now',
	},
	{ # Index: 1.
		address => 'Heaven',
		event   => 'Exit',
		time    => 'Then',
	},
	{ # Index: 2.
		address => 'There',
		event   => 'Finish',
		time    => 'Thus',
	}
];
$keyset	= [qw/address time/];
$index	= Search::InvertedIndex::Simple -> new(dataset => $dataset, keyset => $keyset) -> build_index();

#pwint($index);

trial('three', $index, 'address', 'He', 'time', 'T', '1');
