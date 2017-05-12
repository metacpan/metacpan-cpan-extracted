

use NetAddr::IP;

$| = 1;

print "1..1\n";

my $test = 1;
sub ok() {
  print 'ok ',$test++,"\n";
}


my $ip = new NetAddr::IP('arin.net');
if (defined $ip) {
  print "ok $test	# Skipped, resolved $ip\n";
  $test++;
} else {
  print "ok $test	# Skipped, resolver not working\n";
  $test++;
}

#import NetAddr::IP qw(:nofqdn);
#
#$ip = new NetAddr::IP('arin.net');
#print "unexpected response with :nofqdn\nnot "
#	if defined $ip;
#&ok;
