use strict; use warnings;
use PadWalker 'peek_our';

print "1..2\n";

our $x;
our $h;

($x,$h) = (7);

no warnings 'misc';	# Yes, I know it masks an earlier declaration!
my $h;

$h = peek_our(0);

print (${$h->{'$x'}} eq 7 ? "ok 1\n" : "not ok 1\n");

# our $h is masked by 'my $h':
print (exists($h->{'$h'}) ? "not ok 2\n" : "ok 2\n");
