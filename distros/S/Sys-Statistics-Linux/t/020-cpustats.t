use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

if (!-r '/proc/stat') {
    plan skip_all => "it seems that your system doesn't provide cpu statistics";
    exit(0);
}

plan tests => 5;

my @cpustats = qw(
   user
   nice
   system
   idle
   total
);

my $sys = Sys::Statistics::Linux->new();
$sys->set(cpustats => 1);
sleep(1);
my $stats = $sys->get;
ok(defined $stats->cpustats->{cpu}->{$_}, "checking cpustats $_") for @cpustats;
