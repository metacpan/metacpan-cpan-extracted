use Test::More skip_all => 'Need to write actual tests'; 
use Test::Moose;
use Data::Dumper;
use MooseX::Semantic::Test::Person;

# http://th.atguy.com/mycode/generate_random_string/
sub generate_random_string
{
	my $length_of_randomstring=shift;# the length of 
			 # the random string to generate

	my @chars=('a'..'z','A'..'Z','0'..'9','_');
	my $random_string;
	foreach (1..$length_of_randomstring) 
	{
		# rand @chars will generate a random 
		# number between 0 and scalar @chars
		$random_string.=$chars[rand @chars];
	}
	return $random_string;
}

my $p = MooseX::Semantic::Test::Person->new(
    'name' => 'ABC',
);
my @people = map {
    MooseX::Semantic::Test::Person->new(
        country => generate_random_string(10),
        favorite_numer => $_,
    )
} (1..10);

$people[1]->add_friend( $people[2] );
$people[2]->add_friend( $people[3] );
$people[3]->add_friend( $people[4] );
$people[4]->add_friend( $people[5] );
# warn Dumper $people[1]->export_to_hash;
# warn Dumper $people[1]->rdf_serialize('application/rdf+xml');
# warn Dumper $people[1]->rdf_serialize('application/json', max_recursion=>5);
# # warn Dumper $people[2]->export_to_hash( max_recursion => 2, hash_key => 'Moose' );
# # warn Dumper $people[2]->export_to_hash( max_recursion => 1, hash_key => 'RDF' );
# # warn Dumper $people[2]->export_to_hash( max_recursion => 0, hash_key => 'Moose,RDF' );
# warn Dumper $people[2]->export_to_hash( max_recursion => 2, hash_key => 'Invalid' );
# warn Dumper @people;
