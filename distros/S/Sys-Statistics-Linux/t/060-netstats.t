use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

if (!-r '/proc/net/dev') {
    plan skip_all => "it seems that your system doesn't provide net statistics";
    exit(0);
}

plan tests => 36;

my @netstats = qw(
   rxbyt
   rxpcks
   rxerrs
   rxdrop
   rxfifo
   rxframe
   rxcompr
   rxmulti
   txbyt
   txpcks
   txerrs
   txdrop
   txfifo
   txcolls
   txcarr
   txcompr
   ttpcks
   ttbyt
);

my $sys = Sys::Statistics::Linux->new();
$sys->set(netstats => 1);
sleep(1);
my $stats = $sys->get;

for my $dev (keys %{$stats->netstats}) {
   ok(defined $stats->netstats->{$dev}->{$_}, "checking netstats $_") for @netstats;
   last; # we check only one device, that should be enough
}

for my $dev (keys %{$stats->netinfo}) {
   ok(defined $stats->netstats->{$dev}->{$_}, "checking netstats $_") for @netstats;
   last; # we check only one device, that should be enough
}
