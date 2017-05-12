#!/usr/bin/perl -wT

use strict;

use Test::More tests => 10;

# Use
use_ok('Net::BGP');

# Build the objects
use_ok('Net::BGP::Process');
my $bgp = Net::BGP::Process->new();
ok(ref $bgp eq 'Net::BGP::Process', 'Net::BGP::Process constructor');

use_ok('Net::BGP::Peer');
my $peer = Net::BGP::Peer->new(
    Start      => 0,
    ThisID     => '1.2.3.4',
    ThisAS     => '1',
    PeerID     => '127.0.0.1',
    PeerAS     => '200000',
    SupportAS4 => 1,
    Listen     => 0,
    Passive    => 1
);
ok(ref $peer eq 'Net::BGP::Peer', 'Net::BGP::Peer constructor');

my $transport = new Net::BGP::Transport(parent => $peer);
ok(ref $transport eq 'Net::BGP::Transport', 'sNet::BGP::Transport constructor');

my @msg = qw(
  04 5B A0 00  F0 CC DD EE  FF 10 02 0E
  01 04 00 01  00 01 02 00  41 04 00 03
  0D 40
);

my $ret =
  $transport->_decode_bgp_open_message(join('', map { pack('H2', $_); } @msg));
ok($ret, "Decode BGP OPEN with multi-capability in one option");

ok($transport->can_refresh, "Refresh properly decoded");
ok($transport->can_as4,     "AS4 properly decoded");
ok($transport->can_mbgp,    "MBGP properly decoded");

__END__
