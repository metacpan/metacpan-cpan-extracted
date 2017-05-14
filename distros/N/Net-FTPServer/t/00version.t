use strict;
use Test;

BEGIN {
  plan tests => 1;
}

if( not eval "require Test::More; 1" ){
  print "Bail out!\n";
  printf STDERR "note: Test::More is needed to run tests.\n";
  exit 1;
}

ok(1);

__END__
