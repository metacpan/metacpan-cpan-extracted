use Mojo::Base -strict;
use Test::More;
use Mojo::mysql;
use Mojo::mysql::Database::Role::LoadDataInfile -no_apply;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE});
ok $mysql->db->ping, 'connected';

ok !$mysql->db->can('load_data_infile'), 'load_data_infile not composed when using -no_apply';
ok !$mysql->db->can('load_data_infile_p'), 'load_data_infile_p not composed when using -no_apply';

Mojo::mysql::Database::Role::LoadDataInfile->import;

ok $mysql->db->can('load_data_infile'), 'load_data_infile composed when not using -no_apply';
ok $mysql->db->can('load_data_infile_p'), 'load_data_infile_p composed when not using -no_apply';

done_testing;
