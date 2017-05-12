use 5.010;
use warnings;

use Perl6::Form;

my @data = split "\n", <<EODATA;
**********
*************
***************
************************
********
****************
*****
************
*************
******
EODATA

my $cols  = '_'x@data;
my $axis  = '-'x@data;
my $label = '{|{'.@data.'}|}';

print form {interleave=>1, single=>['_','=']}, <<EOGRAPH,

   ^
 = | $cols
   +-$axis->
     $label
EOGRAPH
"Frequency", @data, "Score";

