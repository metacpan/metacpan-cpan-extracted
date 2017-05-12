
#use diagnostics;
use NetAddr::IP::Lite;

$| = 1;

print "1..9\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}

my @ips = qw(
	126.255.255.255	0
	127.0.0.0	1
	127.0.0.1	1
	127.255.255.254	1
	127.255.255.255	1
	128.0.0.0	0
	::0		0
	::1		1
	::2		0

);


for (my $i=0;$i<=$#ips;$i+=2) {
  my $ip = new NetAddr::IP::Lite($ips[$i]);
  my $got = $ip->is_local();
  my $exp = $ips[$i+1];
  print $ip," got: $got, exp: $exp\nnot "
	unless $got == $exp;
  &ok;
}

