use FindBin;
use lib $FindBin::Bin;
use nmsgtest;

use Test::More tests => 76;

use Net::Nmsg::Util qw( :io :sniff );

my($lo, $hi) = (777, 780);
my @p = ($lo .. $hi);

my @socks = (
  "FF00:0:1:2:3:4:5:6/$lo",
  "1.2.3.4/$lo",
  "1.2.3.4:$lo",
  "wombat.com/$lo",
  "wombat.com:$lo",
);

my @pranges = (
  "FF00:0:1:2:3:4:5:6/$lo..$hi",
  "1.2.3.4/$lo..$hi",
  "1.2.3.4:$lo..$hi",
  "wombat.com/$lo..$hi",
  "wombat.com:$lo..$hi",
);

my @fails = qw(
  FF00:0:1:2:3:4:5:6
  1.2.3.4
  wombat.com
);

sub _cmp_lo {
  cmp_ok(@_, '==', 2, 'socket port lo');
  cmp_ok($_[1], '==', $lo, 'socket port val == lo');
}

sub _cmp_hi {
  cmp_ok(@_, '==', 2, 'socket port hi');
  cmp_ok($_[1], '==', $hi, 'socket port val == hi');
}

sub _cmp_in {
  cmp_ok(@_, '==', 2, 'socket port in');
  cmp_ok($_[1], '>', $lo, 'socket port val > lo');
  cmp_ok($_[1], '<', $hi, 'socket port val < hi');
}

sub _cmp_no {
  my @res = parse_socket_spec($s);
  cmp_ok(@res, '==', 0, 'socket not');
  @res = expand_socket_spec($s);
  cmp_ok(@res, '==', 0, 'socket port range not');
}

_cmp_no($_) for @fails;

_cmp_lo(parse_socket_spec($_)) for @socks;

for my $s (@pranges) {
  my @s = expand_socket_spec($s);
  cmp_ok(@s, '==', @p, 'socket port range');
  _cmp_lo(parse_socket_spec(shift @s));
  _cmp_hi(parse_socket_spec(pop @s));
  _cmp_in(parse_socket_spec($_)) for @s;
}

my $too_hi = $lo + 2 * NMSG_PORT_MAXRANGE;
for my $s (@socks) {
  my @res;
  eval { @res = expand_socket_spec("$s..$too_hi") };
  ok($@ && !@res, 'port range throttle');
}
