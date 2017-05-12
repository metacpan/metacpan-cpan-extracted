#!perl -T
# $RedRiver: 25-decode_linktest.t,v 1.2 2008/02/08 18:49:41 andrew Exp $

use Test::More tests => 3;
use File::Spec;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("25: Parse linktest");

my $linktest = <<'EOL';
[suid] 5 [pkt len] 1600 bytes [# of pkts per cycle] 500 [cycle] 5

0  [AP Tx] 500 [AP Rx] 500 [AP RxErr] 0  [SU Tx] 500 [SU Rx] 500 [SU RxErr] 0  1286 ms  9953 kbps
1  [AP Tx] 500 [AP Rx] 500 [AP RxErr] 0  [SU Tx] 500 [SU Rx] 500 [SU RxErr] 0  1287 ms  9945 kbps
2  [AP Tx] 500 [AP Rx] 500 [AP RxErr] 0  [SU Tx] 500 [SU Rx] 500 [SU RxErr] 0  1288 ms  9937 kbps
3  [AP Tx] 500 [AP Rx] 500 [AP RxErr] 0  [SU Tx] 500 [SU Rx] 500 [SU RxErr] 0  1287 ms  9945 kbps
4  [AP Tx] 500 [AP Rx] 500 [AP RxErr] 0  [SU Tx] 500 [SU Rx] 500 [SU RxErr] 0  1288 ms  9937 kbps

[AP Total nTx]    5000 pkts
[AP Total nRx]    5000 pkts
[AP Total nRxErr] 0 pkts

[SU Total nTx]    5000 pkts
[SU Total nRx]    5000 pkts
[SU Total nRxErr] 0 pkts

[AP to SU Error Rate] 0.00 %
[SU to AP Error Rate] 0.00 %

[Avg of Throughput]   9942 kbps
EOL

$should_decode_to = {
    'tests' => [
    {
        'rate' => '9953 kbps',
        'SU Tx' => '500',
        'time' => '1286 ms',
        'SU RxErr' => '0',
        'SU Rx' => '500',
        'AP Rx' => '500',
        'AP RxErr' => '0',
        'AP Tx' => '500'
    },
    {
        'rate' => '9945 kbps',
        'SU Tx' => '500',
        'time' => '1287 ms',
        'SU RxErr' => '0',
        'SU Rx' => '500',
        'AP Rx' => '500',
        'AP RxErr' => '0',
        'AP Tx' => '500'
    },
    {
        'rate' => '9937 kbps',
        'SU Tx' => '500',
        'time' => '1288 ms',
        'SU RxErr' => '0',
        'SU Rx' => '500',
        'AP Rx' => '500',
        'AP RxErr' => '0',
        'AP Tx' => '500'
    },
    {
        'rate' => '9945 kbps',
        'SU Tx' => '500',
        'time' => '1287 ms',
        'SU RxErr' => '0',
        'SU Rx' => '500',
        'AP Rx' => '500',
        'AP RxErr' => '0',
        'AP Tx' => '500'
    },
    {
        'rate' => '9937 kbps',
        'SU Tx' => '500',
        'time' => '1288 ms',
        'SU RxErr' => '0',
        'SU Rx' => '500',
        'AP Rx' => '500',
        'AP RxErr' => '0',
        'AP Tx' => '500'
    }
    ],
    'AP Total nTx' => '5000 pkts',
    'AP Total nRxErr' => '0 pkts',
    '# of pkts per cycle' => '500',
    'AP Total nRx' => '5000 pkts',
    'SU Total nRxErr' => '0 pkts',
    'SU to AP Error Rate' => '0.00 %',
    'AP to SU Error Rate' => '0.00 %',
    'suid' => '5',
    'SU Total nRx' => '5000 pkts',
    'SU Total nTx' => '5000 pkts',
    'Avg of Throughput' => '9942 kbps',
    'pkt len' => '1600 bytes',
    'cycle' => '5'
};

my @linktest = split /\n/, $linktest;

my $decoded;
ok($decoded = Net::Telnet::Trango::_decode_linktest(@linktest), 
    "Decoding linktest");

is_deeply($decoded, $should_decode_to, "Decoded information matches");
