package MyApp::Database;
use Mojo::Base 'Mojo::mysql::Database';

package main;
use Mojo::Base -strict;
use Test::More;
use Mojo::mysql;
use Mojo::mysql::Database;
use Mojo::mysql::Database::Role::LoadDataInfile database_class => 'MyApp::Database';

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE})->database_class('MyApp::Database');
ok $mysql->db->ping, 'connected';

my $db = $mysql->db;
isa_ok($db, 'MyApp::Database');
can_ok($db, 'load_data_infile', 'load_data_infile_p');

ok !Mojo::mysql::Database->can('load_data_infile'), 'load_data_infile not composed onto Mojo::mysql::Database';
ok !Mojo::mysql::Database->can('load_data_infile_p'), 'load_data_infile_p not composed onto Mojo::mysql::Database';

done_testing;