use Mojo::Base -strict;
use Test::More;

{
  package My::Test::Results;
  use Mojo::Base -base;
  sub foo { 42 }
}

{
  package My::Test::ResultsRole1;
  use Mojo::Base -role;
  requires 'foo';
  sub bar { shift->foo * 2 }
}

{
  package My::Test::ResultsRole2;
  use Mojo::Base -role;
  requires 'bar';
  sub baz { shift->bar + 1 }
}

{
  package My::Test::Database;
  use Mojo::Base -base;
  has results_class => 'My::Test::Results';
  sub get_results { shift->results_class->new }
}

{
  package My::Test::Manager;
  use Mojo::Base -base;
  use Role::Tiny::With;
  sub db { My::Test::Database->new }
  with 'Mojo::DB::Role::ResultsRoles';
}

my $manager = My::Test::Manager->new;

push @{$manager->results_roles}, 'My::Test::ResultsRole1';
my $results = $manager->db->get_results;
isa_ok $results, 'My::Test::Results';
can_ok $results, 'foo';
is $results->foo, 42, 'right foo';
can_ok $results, 'bar';
is $results->bar, 84, 'right bar';

push @{$manager->results_roles}, 'My::Test::ResultsRole2';
$results = $manager->db->get_results;
isa_ok $results, 'My::Test::Results';
can_ok $results, 'foo';
is $results->foo, 42, 'right foo';
can_ok $results, 'bar';
is $results->bar, 84, 'right bar';
can_ok $results, 'baz';
is $results->baz, 85, 'right baz';

done_testing;
