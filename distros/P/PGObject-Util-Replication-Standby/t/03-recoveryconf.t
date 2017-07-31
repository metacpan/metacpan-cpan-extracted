use PGObject::Util::Replication::Standby;
use Test::More;
use strict;
use warnings;

plan tests => 12;

my $standby = PGObject::Util::Replication::Standby->new();
ok($standby, 'Got an SMO for the standby');
ok($standby->recoveryconf, 'Got a config handle for the recovery.conf');
is($standby->connection_string, 'postgresql:///postgres', 
    'empty postgresql connection string by default');
$standby->upstream_host('localhost');
is($standby->connection_string, 'postgresql://localhost/postgres', 
'correct connection string with only host set');
$standby->credentials('foo', 'bar');
is($standby->connection_string, 'postgresql://foo:bar@localhost/postgres',
  'Correct string wtih username, password, host, and dbname');
my $cstring = $standby->connection_string;
like($standby->recoveryconf_contents, qr/$cstring/, 'generated file contains connection string');
like($standby->recoveryconf_contents, qr/standby_mode/, 'standby_mode set');

$standby->from_recoveryconf('t/helpers/recovery.conf');
$standby->set_recovery_param('archive_command', 'true');
$standby->upstream_host('testhost');
$standby->upstream_database('testdb');
diag $standby->upstream_host;;
is($standby->connection_string, 'postgresql://testhost/testdb', 
    'empty postgresql connection string by default');
like($standby->recoveryconf_contents, qr/standby_mode/, 'standby_mode set');

my $standby2 = PGObject::Util::Replication::Standby->new();
mkdir 't/temp';
my $path = 't/temp/test.tmp.conf';
open my $fh, '>', $path;
print $fh $standby->recoveryconf_contents;
close $fh;
$standby2->from_recoveryconf($path);
ok($standby2->recoveryconf->get_value('archive_command'), 
   'Have archive command set in recovery.conf');
ok($standby2->recoveryconf->get_value('standby_mode'), 
   'Have standby mode set in recovery.conf');
is($standby2->connection_string, $standby->connection_string, 'connection strings match');
