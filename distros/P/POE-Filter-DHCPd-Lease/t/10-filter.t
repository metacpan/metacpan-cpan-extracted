#!perl

use strict;
use warnings;
use lib './lib';
use POE::Filter::DHCPd::Lease;
use Time::Local;
use Test::More tests => 16;

my $filter  = POE::Filter::DHCPd::Lease->new;
my $datapos = 1 + tell DATA;
my $buffer;

for my $bufsize (16, 2048) {
    my $ctrl = 100;
    my @macs = qw/001133556611 aaff33552211/;
    my @ends;

    push @ends, timelocal(reverse 2008,6,14, 19,42,32);
    push @ends, timelocal(reverse 2008,7,16,  5,44,51);

    seek DATA, $datapos, 0;

    diag("reading with bufsize $bufsize");

    while($ctrl--) {
        unless(defined read(DATA, $buffer, $bufsize)) {
            skip("read failed: $!", 3);
        }
        unless(length $buffer) {
            last;
        }

        $filter->get_one_start([$buffer]);

        while(1) {
            my $leases = $filter->get_one;

            last unless(@$leases);

            for my $lease (@$leases) {
                my $ends = shift @ends;
                my $mac  = shift @macs;
                ok($lease->{'ip'}, "got lease for $lease->{'ip'}");
                is($lease->{'hw_ethernet'}, $mac, "got lease for $mac");
                is($lease->{'ends'}, $ends, "ends $ends");
            }
        }
    }

    ok($ctrl, "control loop ended before being self destroyed");
    is($filter->get_pending, q(), "no more data in buffer");
}

__DATA__

lease 10.19.83.199 {
  starts 0 2008/07/13 19:42:32;
  ends 1 2008/07/14 19:42:32;
  tstp 1 2008/07/14 19:42:32;
  binding state free;
  hardware ethernet 00:11:33:55:66:11;
}

lease 10.19.83.198 {
  starts 5 2008/08/15 21:40:31;
  ends 6 2008/08/16 05:44:51;
  tstp 6 2008/08/16 05:44:51;
  binding state free;
  hardware ethernet AA:ff:33:55:22:11;
}

