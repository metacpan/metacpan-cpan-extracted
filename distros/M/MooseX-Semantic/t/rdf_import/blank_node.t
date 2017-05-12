use Test::More tests=>8;
use RDF::Trine;
use Data::Dumper;
use MooseX::Semantic::Test::Person;

my $model = RDF::Trine::Model->new;
RDF::Trine::Parser::Turtle
	->new
	->parse_file_into_model('http://example.com/', 't/data/blank_node_01.ttl', $model);

# warn Dumper $model;
# my $serializer = RDF::Trine::Serializer->new('turtle');
# warn Dumper $serializer->serialize_model_to_string($model);
ok( my $alice = MooseX::Semantic::Test::Person->new_from_model($model, 'http://example.com/alice'), 'Alice is detected');
ok( $alice->has_friends, 'Alice has a friend' );
is( $alice->friends->[0]->name, Bob, "Alice's friend's name is Bob" );
ok( $alice->friends->[0]->is_blank, "Bob is a blank node" );
ok( my $alice_inline = MooseX::Semantic::Test::Person->new_from_model($model, 'http://example.com/alice-inline'), 'Alice is detected');
ok( $alice_inline->has_friends, "Alice has a friend Inline" );
is( $alice_inline->friends->[0]->name, "Bob Inline", "Alice's friend's name is Bob Inline" );
ok( $alice_inline->friends->[0]->is_blank, "Bob is a blank node Inline" );


# warn Dumper $alice;
