

use lib "t/springfield";
use Springfield;

tests_for_dialect('mysql');

begin_tests(1);

{
  my $storage = Springfield::connect_empty();

  $storage->insert( NaturalPerson->new( firstName => 'Homer', age => 37 ),
					NaturalPerson->new( firstName => 'Marge', age => 34 ) );

  my $p = $storage->remote('NaturalPerson');

  my @results = $storage->select($p, $p->{age}->bitwise_and(1));
  test @results == 1 && $results[0]{firstName} eq 'Homer';
}

