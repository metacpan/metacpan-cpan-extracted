#!perl
use Test2::V0;
use Proquint ':all';

my $hex   = '7f000001';
my $int   = hex( '0x' . $hex );
my $quint = 'lusab-babad';

my $hex2   = 'dead1234beef';
my $quint2 = 'tupot-damuh-ruroz';

is uint32proquint($int),   $quint, 'uint32proquint ' . $int;
is proquint32uint($quint), $int,   'proquint32uint ' . $quint;

is hex2proquint($hex),   $quint, 'hex2proquint ' . $hex;
is proquint2hex($quint), $hex,   'proquint2hex ' . $quint;

is hex2proquint($hex2),   $quint2, 'hex2proquint ' . $hex2;
is proquint2hex($quint2), $hex2,   'proquint2hex ' . $quint2;

done_testing();
