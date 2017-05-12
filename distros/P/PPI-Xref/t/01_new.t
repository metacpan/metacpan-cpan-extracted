use Test::More;

use strict;
use warnings;

use PPI::Xref;

my $xref = PPI::Xref->new();

isa_ok($xref, 'PPI::Xref');

done_testing();
