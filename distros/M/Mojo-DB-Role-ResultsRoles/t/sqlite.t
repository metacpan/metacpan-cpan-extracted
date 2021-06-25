use Mojo::Base -strict;
use Test::Needs {'Mojo::SQLite' => '1.000'};

use Test::More;

{
  package My::Test::ResultsRole1;
  use Mojo::Base -role;
  has foo => sub { shift->arrays->first->[0] };
}

{
  package My::Test::ResultsRole2;
  use Mojo::Base -role;
  requires 'foo';
  sub bar { shift->foo + 1 }
}

my $sqlite = Mojo::SQLite->new->with_roles('Mojo::DB::Role::ResultsRoles');

push @{$sqlite->results_roles}, 'My::Test::ResultsRole1';
my $results = $sqlite->db->query('SELECT 4');
isa_ok $results, 'Mojo::SQLite::Results';
is @{$results->columns}, 1, 'right columns';
can_ok $results, 'foo';
is $results->foo, 4, 'right foo';

push @{$sqlite->results_roles}, 'My::Test::ResultsRole2';
$results = $sqlite->db->query('SELECT 42');
isa_ok $results, 'Mojo::SQLite::Results';
is @{$results->columns}, 1, 'right columns';
can_ok $results, 'foo';
is $results->foo, 42, 'right foo';
can_ok $results, 'bar';
is $results->bar, 43, 'right bar';

done_testing;
