#!/usr/bin/perl

use strict;
use Net::Pcap::Easy;
use File::Slurp qw(slurp);

use Test; my $pings = 10;
plan tests => (my $max = $pings * 3);

# NOTE: there's little doubt with all the time sensitive things going on
# here that I'll see this on the CPAN tresters reports eventually...

my $dev;
if( -s "device" ) {
    $dev = slurp('device');
    chomp $dev;
}

unless( $dev ) {
    warn "   [skipping tests: no device given]\n";
    skip(1, 0,0) for 1 .. $max;
    exit 0;
}
 
eval "use Net::Ping";
if( $@ ) {
    warn "   [skipping tests: no Net::Ping module]\n";
    skip(1, 0,0) for 1 .. $max;
    exit 0;
}

$SIG{ALRM} = sub { exit 1 }; alarm 15;

my $ppid = $$;
my $kpid = fork;
if( not $kpid ) {
    my $val = 1;
    $SIG{HUP} = sub { $val = 0; };

    sleep 1 while $val;

    my $p = eval { Net::Ping->new('icmp') }; exit 0 if $@; # Net::Ping needs root, warned and described below
       $p->ping("voltar.org") for 1 .. $pings;
       $p->close;

    exit 0;
}

my $npe = eval { Net::Pcap::Easy->new(
    dev              => $dev,
    filter           => "icmp",
    promiscuous      => 0,
    packets_per_loop => $pings,

    icmp_callback => sub {
        my ($npe, $ether, $ip, $icmp) = @_;

        ok( $ip->{src_ip},  qr(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) );
        ok( $ip->{dest_ip}, qr(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) );
        ok( $npe->is_local( $ip->{src_ip} ) or $npe->is_local( $ip->{dest_ip} ) );
    },
)};

my $skip;
if( $@ ) {
    if( $@ =~ m/(?:permission|permitted)/i ) {
        $skip = 1;

    } else {
        die "problem loading npe: $@";
    }
}

kill 1, $kpid;
if( $skip ) {
    warn "   [skipping tests: permission denied, try running as root]\n";
    skip(1, 0,0) for 1 .. $max;

} else {
    $npe->loop;
}

waitpid $kpid, 0;
exit 0;
