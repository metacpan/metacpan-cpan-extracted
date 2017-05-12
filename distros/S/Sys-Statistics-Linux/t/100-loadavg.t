use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

if (!-r '/proc/loadavg') {
    plan skip_all => "it seems that your system doesn't provide load statistics";
    exit(0);
}

plan tests => 3;

my @loadavg = qw(
   avg_1
   avg_5
   avg_15
);

my $sys = Sys::Statistics::Linux->new();
$sys->set(loadavg => 1);
my $stats = $sys->get;
ok(defined $stats->{loadavg}->{$_}, "checking loadavg $_") for @loadavg;
