use Mojo::Base -strict;
 
use Test::More;
use Mojo::SQLite;
# use Mojo::Pg;
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;


my $sql = Mojo::SQLite->new;

# ('sqlite:test.db');
# my $pg = Mojo::Pg->new('postgresql://ingiro@/ingiro');


my $db = $sql->db;
$db->query(
	   'create table if not exists crud_test (
             id   integer primary key autoincrement,
            name text
           )'
  );

$db = $db->with_roles('Mojo::DB::Role::DBIx::Class');

isa_ok($db->dbic, 'DBIx::Class::Schema::Loader', 'isa Loader');

ok([ $db->dbic->sources ]->[0] eq 'CrudTest', 'resultset exists');

ok($db->resultset('CrudTest') == 0, 'resultset is empty');

$db->resultset('CrudTest')->create({ name => 'some name' });

ok($db->resultset('CrudTest') == 1, 'record inserted');
ok($db->resultset('CrudTest')->first->name eq 'some name', 'field correct');

$db->resultset('CrudTest')->create({ name => 'some other name' });

ok($db->resultset('CrudTest') == 2, 'another record inserted');

$db->resultset('CrudTest')->update_or_create({ name => 'updated name', id => 1 });

ok($db->resultset('CrudTest')->find({ id => 1 })->name eq 'updated name', 'field updated correctly');

ok($db->resultset('CrudTest') == 2, 'record updated not inserted');

done_testing()
