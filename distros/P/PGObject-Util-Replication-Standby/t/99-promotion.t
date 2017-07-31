#!/usr/bin/perl 
diag(`whoami`);
use PGObject::Util::Replication::Standby;
use Test::More;
use Data::Dumper;

plan skip_all => 'DB_TESTING not set up' unless $ENV{DB_TESTING};

plan tests => 9;

my $standby = PGObject::Util::Replication::Standby->new(user => 'travis');
ok($standby, 'have a standby');
$standby->from_recoveryconf('/var/lib/postgresql/9.6/replica/recovery.conf');

open my $fh, '<', '/var/lib/postgresql/9.6/replica/recovery.conf' or diag($!);
my $file = join "", <$fh>;
close $fh;
diag($file);

ok($standby->recoveryconf->get_value('trigger_file'), 'trigger file defined') or diag(Dumper($standby->recoveryconf));

my $trigger_file = $standby->recoveryconf->get_value('trigger_file');
$standby->recoveryconf->set('trigger_file', '');
ok((not $standby->recoveryconf->get_value('trigger_file')), 'trigger file defined');

ok(-f $standby->recoveryconf_path, 'recovery.conf exists');
ok($standby->promote, 'Deleted recovery.conf');
ok((not -f $standby->recoveryconf_path), 'Recovery.conf no longer exists');
ok((not $standby->promote), 'false when standby->promote has no trigger file and no recovery.conf exists');
$standby->recoveryconf->set('trigger_file', $trigger_file);
ok($standby->promote, 'success with trigger file');
ok((not $standby->is_recovering), 'Standby is promoted');
