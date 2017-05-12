#!./rxperl

require 5.006;

use lib 'blib/arch';
use Rx;
use Data::Dumper;

my $h = Rx::pl_instrument(shift() || 'fish', '');

print Dumper($h);

1;
1;
1;
