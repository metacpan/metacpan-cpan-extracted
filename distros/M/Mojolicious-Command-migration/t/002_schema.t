use Mojo::Base -strict;
use Data::Dumper;
use Test::More; 
use lib 'lib';
 
plan skip_all => 'set TEST_ONLINE to enable this test'
	unless $ENV{TEST_ONLINE};

use_ok 'Mojolicious::Command::migration';

my $config = do 't/mysql.conf';

my $migration = Mojolicious::Command::migration->new;
$migration->config($config);

ok $migration->description, 'has a description';

eval { $migration->run() };
like $@, qr/Usage/, 'right error';

eval { $migration->run('badcommand') };
like $@, qr/Usage/, 'right error';


my $db = DBI->connect('dbi:mysql:'.$config->{datasource}->{database}, $config->{user}, $config->{password});
$db->do('drop table if exists test') if @{$db->selectall_arrayref('show tables', { Slice => {} })};

my $source = $migration->get_schema(
	to => 'MySQL',
);
isa_ok $source->{schema}, 'SQL::Translator::Schema';
is $source->{schema}->{_ERROR}, 'No tables', 'right';

is @{ $source->{data} }, 3, 'right output';
like $source->{data}->[0], qr/Created by SQL::Translator::Producer::MySQL/, 'right result';
like $source->{data}->[0], qr/Created on/, 'right result';
like $source->{data}->[1], qr/SET foreign_key_checks=0/, 'right result';
like $source->{data}->[2], qr/SET foreign_key_checks=1/, 'right result';


$db->do('create table test (id int(11))');

$source = $migration->get_schema(
	to => 'MySQL',
);

isa_ok $source->{schema}, 'SQL::Translator::Schema';
is $source->{schema}->{_ERROR}, '', 'right';
is @{ $source->{data} }, 4, 'right output';
like $source->{data}->[0], qr/Created by SQL::Translator::Producer::MySQL/, 'right result';
like $source->{data}->[0], qr/Created on/, 'right result';
like $source->{data}->[1], qr/SET foreign_key_checks=0/, 'right result';
is $source->{data}->[2], '--
-- Table: `test`
--
CREATE TABLE `test` (
  `id` integer(11) NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8', 'right result';

like $source->{data}->[3], qr/SET foreign_key_checks=1/, 'right result';

$source = $migration->deployment_statements(
	filename    => "t/sql/001_deploy.sql",
);
is @$source, 2, 'right output';
like $source->[0], qr/^SET foreign_key_checks=0/, 'right result';
like $source->[1], qr/^CREATE TABLE/, 'right result';

$source = $migration->deployment_statements(
	filename    => "t/sql/001_upgrade.sql",
);
is @$source, 1, 'right output';
is $source->[0], "ALTER TABLE test ADD COLUMN name varchar(255) NOT NULL DEFAULT ''", 'right result';

done_testing;