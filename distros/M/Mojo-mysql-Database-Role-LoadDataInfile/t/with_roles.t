use Mojo::Base -strict;
use Test::More;
use Mojo::mysql;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE});
$mysql->max_connections(2);
ok $mysql->db->ping, 'connected';

my $db1 = $mysql->db;
my $db2 = $mysql->db;

isnt $db1, $db2, 'dbs not equal'.

ok !$db1->can('load_data_infile'), 'load_data_infile not composed';
ok !$db1->can('load_data_infile_p'), 'load_data_infile_p';

ok !$db2->can('load_data_infile'), 'load_data_infile not composed';
ok !$db2->can('load_data_infile_p'), 'load_data_infile_p not composed';

$db1->with_roles('+LoadDataInfile');

ok $db1->can('load_data_infile'), 'load_data_infile composed after using with_roles';
ok $db1->can('load_data_infile_p'), 'load_data_infile_p composed after using with_roles';

ok !$db2->can('load_data_infile'), 'load_data_infile not composed when not calling with_roles';
ok !$db2->can('load_data_infile_p'), 'load_data_infile_p not composed when not calling with_roles';

done_testing;
