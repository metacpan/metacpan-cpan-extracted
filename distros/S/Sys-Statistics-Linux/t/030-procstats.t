use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

if (!-r '/proc/stat' || !-r '/proc/loadavg') {
    plan skip_all => "it seems that your system doesn't provide process statistics";
    exit(0);
}

plan tests => 3;

my @procstats = qw(
   new
   runqueue
   count
);

my $sys = Sys::Statistics::Linux->new();
$sys->set(procstats => 1);
sleep(1);
my $stats = $sys->get;
ok(defined $stats->procstats->{$_}, "checking procstats $_") for @procstats;
