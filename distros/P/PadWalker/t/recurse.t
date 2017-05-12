use strict;
use PadWalker 'peek_my';

print "1..2\n";

sub rec {
  my ($arg) = @_;
  my $var = 'first';;
  if ($arg) {
    $var = 'second';
    my ($h0, $h1) = map peek_my($_), 0, 1;
    print((${$h0->{'$var'}} eq 'second' ? "ok " : "not ok "), "1\n",
          (${$h1->{'$var'}} eq 'first'  ? "ok " : "not ok "), "2\n");
  } else {
    rec(1);
  }
}

rec();
