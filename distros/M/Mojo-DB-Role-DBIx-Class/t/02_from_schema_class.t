use Mojo::Base -strict;
 
use Test::More;
use Mojo::SQLite;
use Mojo::Util qw/dumper/;

use FindBin qw($Bin);
use lib "$Bin/lib";

my $sql = Mojo::SQLite->new;

my $db = $sql->db;

$db = $db->with_roles('Mojo::DB::Role::DBIx::Class');

$db->dbic('Test::Schema');

$db->dbic->deploy;

ok([ $db->dbic->sources ]->[0] eq 'CrudTest', 'resultset exists');

ok($db->resultset('CrudTest') == 0, 'resultset is empty');

$db->resultset('CrudTest')->create({ name => 'some name' });

ok($db->resultset('CrudTest') == 1, 'record inserted');

ok($db->resultset('CrudTest')->first->name eq 'some name', 'field correct');

isa_ok($db->resultset('CrudTest')->first->insert_time, 'DateTime');

$db->resultset('CrudTest')->create({ name => 'some other name' });

ok($db->resultset('CrudTest') == 2, 'another record inserted');

$db->resultset('CrudTest')->update_or_create({ name => 'updated name', id => 1 });

ok($db->resultset('CrudTest')->find({ id => 1 })->name eq 'updated name', 'field updated correctly');

ok($db->resultset('CrudTest') == 2, 'record updated not inserted');

done_testing()
