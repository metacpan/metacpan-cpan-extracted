use Test::More;
use PGObject::Util::DBAdmin;
use Test::Exception;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 9;

my $db = PGObject::Util::DBAdmin->new(
   username => 'postgres'        ,
   host     => 'localhost'       ,
   port     => '5432'            ,
   dbname   => 'pgobject_test_db',
);

eval { $db->drop };

lives_ok { $db->create } 'Create db, none exists';
dies_ok { $db->create } 'create db, already exists';
dies_ok { $db->run_file(file => 't/data/does_not_exist.sql') }
        'bad file input for run_file';
dies_ok { $db->run_file(file => 't/data/bad.sql') } 'sql file errors';
lives_ok { $db->drop } 'drop db first time, successful';
dies_ok { $db->drop } 'dropdb second time, dies';
dies_ok { $db->backup(format => 'c') } 'cannot back up non-existent db';
dies_ok { $db->restore(format => 'c', file => 't/data/backup.sqlc') } 'cannot restore to non-existent db';

$db = PGObject::Util::DBAdmin->new(
   username => 'postgres'        ,
   host     => 'localhost'       ,
   port     => '2'            ,
   dbname   => 'pgobject_test_db',
);

dies_ok { $db->connect } 'Could not connect';
