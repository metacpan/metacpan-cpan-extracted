use Test::More tests => 3;

use_ok( 'Parallel::Workers' );
use File::Basename;
use Data::Dumper;

#
#SSH JOB
###################################################################################
@hosts=(
  'localhost',
);

my $worker=Parallel::Workers->new(
                                    maxworkers=>5,timeout=>10, 
                                    backend=>"SSH", constructor =>{user=>'demo',pass=>'demo'}
                                  );


$id=$worker->create(hosts => \@hosts, command=>"cat /proc/cmdline",
                                      transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',regex => qr/.+/m}); 

$info=$worker->info();
ok($info->{$id}{'localhost'}{do} =~ /root=/, "id=$id, localhost do =~/root=/");

$id=$worker->create(hosts => \@hosts, 
                  pre=>"system",preparams=>("\"echo 'Olivier' >perl-test-olivier\""), 
                  command=>"cat /tmp/perl-test-olivier",
                  post=>"system", postparams=>"\"rm perl-test-olivier\"");

$info=$worker->info();
ok($info->{$id}{'localhost'}{do} ='Olivier\n', "id=$id, localhost do =~'Olivier'");

#print Dumper $info;



