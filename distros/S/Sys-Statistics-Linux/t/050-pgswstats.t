use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

my @pgswstats = qw(
   pgpgin
   pgpgout
   pswpin
   pswpout
);

my $sys = Sys::Statistics::Linux->new();

if (!-r '/proc/diskstats' || !-r '/proc/partitions' || !-r '/proc/stat' || !-r '/proc/vmstat') {
    plan skip_all => "it seems that your system doesn't provide paging/swapping statistics";
    exit(0);
}

plan tests => 4;

$sys->set(pgswstats => 1);
sleep(1);
my $stats = $sys->get;
ok(defined $stats->pgswstats->{$_}, "checking pgswstats $_") for @pgswstats;
