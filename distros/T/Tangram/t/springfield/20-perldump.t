

use lib "t/springfield";
use Springfield;

begin_tests(1);

my $id;

{
  my $storage = Springfield::connect_empty();

  $id = $storage
	->insert( NaturalPerson->new( firstName => 'Homer',
								  brains => {
											 likes => [ qw( beer food ) ],
											 dislikes => [ qw( Flanders taxes ) ],
											} ) );

  $storage->disconnect();
}

{
  my $storage = Springfield::connect();

  my $homer = $storage->load($id);
  test( join('|', sort keys %{ $homer->{brains} }) eq 'dislikes|likes'
		&& "@{ $homer->{brains}{likes} }" eq 'beer food'
		&& "@{ $homer->{brains}{dislikes} }" eq 'Flanders taxes' );

  $storage->disconnect();
}


