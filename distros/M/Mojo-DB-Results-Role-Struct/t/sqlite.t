use Mojo::Base -strict;
use Test::Needs {'Mojo::SQLite' => '1.000'}, 'Mojo::DB::Role::ResultsRoles';

use Test::More;

my $sqlite = Mojo::SQLite->new->with_roles('Mojo::DB::Role::ResultsRoles');
push @{$sqlite->results_roles}, 'Mojo::DB::Results::Role::Struct';

my $results = $sqlite->db->query('SELECT 4 AS "foo", 42 AS "bar"');
is_deeply $results->columns, [qw(foo bar)], 'right columns';
my $struct = $results->structs->first;
is $struct->foo, 4, 'right foo';
is $struct->bar, 42, 'right bar';

done_testing;
