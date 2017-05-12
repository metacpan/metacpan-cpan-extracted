
use strict;
use Net::Pcap::Easy;
use Test;
use Data::Dumper;
use File::Slurp qw(slurp);

plan tests => my $max = 3;

my $dev;
if( -s "device" ) {
    $dev = slurp('device');
    chomp $dev;
}

unless( $dev ) {
    warn "   [skipping tests: no device given]\n";
    UGH_DIE:
    skip(1, 0,0) for 1 .. $max;
    exit 0;
}

my $npe;
unless(
eval {
$npe = Net::Pcap::Easy->new(
    dev              => $dev,
    promiscuous      => 1,
    packets_per_loop => 1,
    default_callback => sub {},
);
}) {
        if( $@ =~ m/(?:permission|permitted)/i ) {
            warn "   [skipping tests: permission denied, try running as root]\n";

        } else {
            warn "couldn't open $dev: $@";
        }

        goto UGH_DIE;
    }

$npe->loop;

my $stats = $npe->stats;

ok( $stats->{recv} >0 );
ok( defined($stats->{drop})   and $stats->{drop}   >= 0 );
ok( defined($stats->{ifdrop}) and $stats->{ifdrop} >= 0 );
