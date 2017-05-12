#!/usr/bin/env  perl
use Data::Dumper;

use Test::More tests => ($ENV{MPICH_MPD_TEST})?8:2;
use File::Basename;

use_ok('Parallel::Mpich::MPD');

#$Parallel::Mpich::MPD::Common::DEBUG=1;
#$Parallel::Mpich::MPD::Common::WARN=1;
$Parallel::Mpich::MPD::Common::TEST=1;


ok(Parallel::Mpich::MPD::Common::env_Hostsfile(dirname(0)."/t/localhost"),"set hostfile :".dirname(0)."/localhost");

exit 0 unless $ENV{MPICH_MPD_TEST};

print STDERR "\n\n# ------------------->the «ssh localhost» will be called for each command...\n";
print STDERR "# ------------------->ENTER PASSWORD \n\n";


ok(Parallel::Mpich::MPD::boot(), "boot mpd if not already up");

my %info=Parallel::Mpich::MPD::info();
print Dumper \%info;
ok($info{port}=~/\S+/ , "checking mpd info :master $info{master} ");
ok($info{port}=~/\d{4}/ , "checking mpd info :port $info{port} ");
ok($info{hostname}=~/\S+/ , "checking mpd info :host $info{hostname}");



ok(Parallel::Mpich::MPD::shutdown(), "shutdown mpd");
#ok(Parallel::Mpich::MPD::clean(pkill=>1), "clean jobs");
