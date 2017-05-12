#!/usr/bin/perl -w
# vim:set ft=perl:

use strict;

use Cwd qw(cwd);
use File::Spec;
use MySQL::Config qw(load_defaults parse_defaults);
use Test::More;

plan tests => 44;

$MySQL::Config::GLOBAL_CNF = File::Spec->catfile(cwd, qw(t my.cnf));

my $count = 0;
my @argv;
load_defaults 'my', [ 'nested' ], \$count, \@argv;

is(scalar @argv, 21, "scalar(\@ARGV) == " . scalar(@argv));
is($count, 21, "\$count == $count");

is($argv[0], '--port=3306', '--port=3306');
is($argv[1], '--socket=/tmp/mysql.sock', '--socket=/tmp/mysql.sock');
is($argv[2], '--skip-locking=1', '--skip-locking=1');
is($argv[3], '--set-variable=key_buffer=16M', '--set-variable=key_buffer=16M');
is($argv[4], '--set-variable=max_allowed_packet=1M', '--set-variable=max_allowed_packet=1M');
is($argv[5], '--set-variable=table_cache=64', '--set-variable=table_cache=64');
is($argv[6], '--set-variable=sort_buffer=512K', '--set-variable=sort_buffer=512K');
is($argv[7], '--set-variable=net_buffer_length=8K', '--set-variable=net_buffer_length=8K');
is($argv[8], '--set-variable=myisam_sort_buffer_size=8M', '--set-variable=myisam_sort_buffer_size=8M');
is($argv[9], '--log-bin=1', '--log-bin=1');
is($argv[10], '--server-id=1', '--server-id=1');
is($argv[11], '--innodb_data_home_dir=/usr/local/var/', '--innodb_data_home_dir=/usr/local/var/');
is($argv[12], '--innodb_data_file_path=ibdata1:10M:autoextend', '--innodb_data_file_path=ibdata1:10M:autoextend');
is($argv[13], '--innodb_log_group_home_dir=/usr/local/var/', '--innodb_log_group_home_dir=/usr/local/var/');
is($argv[14], '--innodb_log_arch_dir=/usr/local/var/', '--innodb_log_arch_dir=/usr/local/var/');
is($argv[15], '--set-variable=innodb_buffer_pool_size=16M', '--set-variable=innodb_buffer_pool_size=16M');
is($argv[16], '--set-variable=innodb_additional_mem_pool_size=2M', '--set-variable=innodb_additional_mem_pool_size=2M');
is($argv[17], '--set-variable=innodb_log_file_size=5M', '--set-variable=innodb_log_file_size=5M');
is($argv[18], '--set-variable=innodb_log_buffer_size=8M', '--set-variable=innodb_log_buffer_size=8M');
is($argv[19], '--innodb_flush_log_at_trx_commit=1', '--innodb_flush_log_at_trx_commit=1');
is($argv[20], '--set-variable=innodb_lock_wait_timeout=50', '--set-variable=innodb_lock_wait_timeout=50');

my %opts = parse_defaults "my", [ 'nested' ];

is($opts{'port'}, 3306, "\$opts{'port'} = 3306");
is($opts{'socket'}, '/tmp/mysql.sock', "\$opts{'socket'} = '/tmp/mysql.sock'");
is($opts{'skip-locking'}, 1, "\$opts{'skip-locking'} = 1");
is($opts{'log-bin'}, '1', "\$opts{'log-bin'} = '1'");
is($opts{'server-id'}, '1', "\$opts{'server-id'} = '1'");
is($opts{'innodb_data_home_dir'}, '/usr/local/var/', "\$opts{'innodb_data_home_dir'} = '/usr/local/var/'");
is($opts{'innodb_data_file_path'}, 'ibdata1:10M:autoextend', "\$opts{'innodb_data_file_path'} = 'ibdata1:10M:autoextend'");
is($opts{'innodb_log_group_home_dir'}, '/usr/local/var/', "\$opts{'innodb_log_group_home_dir'} = '/usr/local/var/'");
is($opts{'innodb_log_arch_dir'}, '/usr/local/var/', "\$opts{'innodb_log_arch_dir'} = '/usr/local/var/'");
is($opts{'innodb_flush_log_at_trx_commit'}, '1', "\$opts{'innodb_flush_log_at_trx_commit'} = '1'");
is($opts{'set-variable'}->{'innodb_lock_wait_timeout'}, '50', "\$opts{'set-variable'}->{'innodb_lock_wait_timeout'} = '50'");
is($opts{'set-variable'}->{'key_buffer'}, '16M', "\$opts{'set-variable'}->{'key_buffer'} = '16M'");
is($opts{'set-variable'}->{'max_allowed_packet'}, '1M', "\$opts{'set-variable'}->{'max_allowed_packet'} = '1M'");
is($opts{'set-variable'}->{'table_cache'}, '64', "\$opts{'set-variable'}->{'table_cache'} = '64'");
is($opts{'set-variable'}->{'sort_buffer'}, '512K', "\$opts{'set-variable'}->{'sort_buffer'} = '512K'");
is($opts{'set-variable'}->{'net_buffer_length'}, '8K', "\$opts{'set-variable'}->{'net_buffer_length'} = '8K'");
is($opts{'set-variable'}->{'myisam_sort_buffer_size'}, '8M', "\$opts{'set-variable'}->{'myisam_sort_buffer_size'} = '8M'");
is($opts{'set-variable'}->{'innodb_buffer_pool_size'}, '16M', "\$opts{'set-variable'}->{'innodb_buffer_pool_size'} = '16M'");
is($opts{'set-variable'}->{'innodb_additional_mem_pool_size'}, '2M', "\$opts{'set-variable'}->{'innodb_additional_mem_pool_size'} = '2M'");
is($opts{'set-variable'}->{'innodb_log_file_size'}, '5M', "\$opts{'set-variable'}->{'innodb_log_file_size'} = '5M'");
is($opts{'set-variable'}->{'innodb_log_buffer_size'}, '8M', "\$opts{'set-variable'}->{'innodb_log_buffer_size'} = '8M'");

