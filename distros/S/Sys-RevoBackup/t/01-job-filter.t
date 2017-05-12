#!perl -T

use Test::More tests => 7;
use Sys::RevoBackup;
use Config::Yak;
use Test::MockObject::Universal;
use File::Temp qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1 );

my $MO = Test::MockObject::Universal::->new();
my $Cfg = Config::Yak::->new({
  'locations' => [],
});
$Cfg->set('Sys::RevoBackup::Verbose',0);
$Cfg->set('Sys::RevoBackup::Dry',1);
$Cfg->set('Sys::RevoBackup::Vaults::Apple',1);
$Cfg->set('Sys::RevoBackup::Vaults::Bananas',1);
my $args = {
    'config'    => $Cfg,
    'logger'    => $MO,
    'logfile'   => $tempdir.'/log',
    'bank'      => $tempdir,
    'concurrency' => 1,
    'job_filter' => 'bananas',
};

my $Revo = Sys::RevoBackup::->new($args);

my $Jobs = $Revo->jobs();

is(scalar(@{$Jobs->jobs()}),1,'Job Queue contains exactly one Job');
is($Jobs->jobs()->[0]->{'name'},'bananas','Job Queue contains the correct Job');

#
# Reset Object
#
$Revo = undef;
$Jobs = undef;

#
# Setup new Object
# without a job filter, so it should get all jobs defined above
#
delete($args->{'job_filter'});
$Revo = Sys::RevoBackup::->new($args);
$Jobs = $Revo->jobs();

is(scalar(@{$Jobs->jobs()}),2,'Job queue now contains exactly two Jobs');

#
# Reset Object
#
$Revo = undef;
$Jobs = undef;

#
# Setup new object to test our sudo feature
#
# this setting is deprecated and should not trigger sudo being present in command
$Cfg->set('Sys::RevoBackup::Sudo',1);

$Revo = Sys::RevoBackup::->new($args);
$Jobs = $Revo->jobs();

my $Worker = $Jobs->jobs()->[0]->worker();
my $rsync_cmd = $Worker->_rsync_cmd();
unlike( $rsync_cmd, qr/--rsync-path=.*sudo.*rsync/, 'Rsync CMD contains rsync path w/o sudo');

#
# Reset Object
#
$Revo   = undef;
$Jobs   = undef;
$Worker = undef;
$rsync_cmd = undef;

# this is the new way of setting sudo
print $Cfg->dump();
$Cfg->set('Sys::RevoBackup::Vaults::Apple::Sudo',1);
$Cfg->set('Sys::RevoBackup::Vaults::Bananas::Sudo',1);

$Revo = Sys::RevoBackup::->new($args);
$Jobs = $Revo->jobs();

my $Worker = $Jobs->jobs()->[0]->worker();
my $rsync_cmd = $Worker->_rsync_cmd();
like( $rsync_cmd, qr/--rsync-path=.*sudo.*rsync/, 'Rsync CMD contains rsync path w/ sudo');
like( $rsync_cmd, qr/-oBatchMode=yes/, 'SSH Options contain ssh Batch Mode');
like( $rsync_cmd, qr/-oStrictHostKeyChecking=no/, 'SSH Options do contain StrictHostKeyChecking=no');
#
# Reset Object
#
$Revo   = undef;
$Jobs   = undef;
$Worker = undef;
$rsync_cmd = undef;

