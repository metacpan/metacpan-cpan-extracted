use Test::More tests => 7;

use_ok( 'Parallel::Workers' );
use_ok( 'Parallel::Workers::Transaction' );
use File::Basename;
use Data::Dumper;

my @hosts=(
  'host-1',
  'host-2',
);
my $id;
$Parallel::Workers::WARN=1;
#
#LOCAL JOB
###################################################################################
my $worker=Parallel::Workers->new(maxworkers=>5,timeout=>10, backend=>"Eval");
ok(defined($worker),"new local worker");

$id=$worker->create(hosts => \@hosts, 
                              command=>"`echo olivier`"
                     );
$info=$worker->info();
ok($info->{$id}{'host-1'}{do} eq "olivier\n", "id=$id, host-13 do = olivier ");
ok(!defined ($info->{$id}{'host-1'}{pre}), "id=$id, host-13 pre is UNDEF");
ok(!defined ($info->{$id}{'host-1'}{post}), "id=$id, host-13 post is UNDEF");

$id=$worker->create(hosts => \@hosts, 
                              pre=>"`echo olivier >/dev/null`",
                              command=>"system", params=>"\"ls -l slk\"",
                              transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',regex => qr/.+/m}
                     );
$info=$worker->info();
ok(!defined ($info->{$id}{'host-1'}{do}), "id=$id, host-13 do = UNDEF ");

#print Dumper ($info);





