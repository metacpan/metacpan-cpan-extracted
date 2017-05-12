use Test::More tests => 6;

use_ok( 'Parallel::Workers' );
use File::Basename;
use Data::Dumper;

my @hosts=(
  'host-1',
  'host-2',
  'host-3',
  'host-4',
  'host-5',
  'host-6',
  'host-7',
  'host-8',
  'host-9',
  'host-10',
  'host-11',
  'host-12',
  'host-13',
  'host-14',
  'host-15',
  'host-16',
  'host-17',
  'host-18',
  'host-19'
);
my $id;
$Parallel::Workers::WARN=1;
#
#LOCAL JOB
###################################################################################
my $worker=Parallel::Workers->new(maxworkers=>15,timeout=>10, backend=>"Eval");
ok(defined($worker),"new local worker");

$id=$worker->create(hosts => \@hosts, command=>"`date`", transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',regex => qr/.+/m});
$info=$worker->info();
ok($info->{$id}{'host-13'}{cmd} eq '`date`', "id=$id, host-13 command = `date` ");
ok($info->{$id}{'host-13'}{do} =~ m/.+/, "id=$id, host-13 do =~ '/.+/' ");
@hosts=(
  'host-1',
);

$worker->clear;
$id=$worker->create(hosts => \@hosts, command=>"`date2 2>/dev/null`", transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',regex => qr/.+/m});
$info=$worker->info();
ok($info->{$id}{'host-1'}{cmd} eq '`date2 2>/dev/null`', "id=$id, host-1 command = date2  ");
ok(!(  $info->{$id}{'host-1'}{do}) , "id=$id, host-1 do ==> " .Dumper $info->{$id}{'host-1'}{do});

#print Dumper $info;





