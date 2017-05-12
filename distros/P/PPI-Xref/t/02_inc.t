use Test::More;

use strict;
use warnings;

use PPI::Xref;

print "# INC = @INC\n";

SKIP: {
  skip("no directory $INC[0]", 1) unless -d $INC[0];
  my $xref = PPI::Xref->new();
  is_deeply($xref->INC->[0], $INC[0], "implicit INC directory $INC[0]");
}

SKIP: { 
  skip("no directory /usr", 1) unless -d '/usr';
  my $xref = PPI::Xref->new({INC => ['/usr']});
  is_deeply($xref->INC, ["/usr"], "explicit INC directory /usr");
}

done_testing();
