# -*- perl -*-
#
# Tests whether lexical values are available in aliased classes
#

use Test::More tests => 4;
#use Test::More qw/no_plan/;
use lib 't/lib';

use Package::Alias 
    'CharlesBrown' => 'Janiva::Magness',
    'Sharon::Jones' => 'DrMichaelWhite';

package Janiva::Magness; use Test::More; my $ab = "Janiva::Magness";
package CharlesBrown; use Test::More;
package DrMichaelWhite; use Test::More; my $d = "DrMichaelWhite";
package Sharon::Jones; use Test::More;

# Originals
package Janiva::Magness;
is $ab, "Janiva::Magness", "Original: Janiva::Magness";

package DrMichaelWhite;
is $d, "DrMichaelWhite", "Original: DrMichaelWhite";

package CharlesBrown;
is $ab, "Janiva::Magness", "Alias: CharlesBrown";

package Sharon::Jones;
is $d, "DrMichaelWhite", "Alias: Sharon::Jones";
