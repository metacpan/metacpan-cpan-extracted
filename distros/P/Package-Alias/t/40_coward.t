# -*- perl -*-
#
# Tests whether Package::Alias will blow away an existing namespace.
#

use Test::More tests => 6;
use Test::Output;

use lib 't/lib';

package Janiva::Magness; $var = "Janiva::Magness";
package CharlesBrown; $var = "CharlesBrown";
package DrMichaelWhite; $var = "DrMichaelWhite";

package main;

use Package::Alias 'Sharon::Jones' => 'DrMichaelWhite';

stderr_like( 
    sub { Package::Alias->alias('CharlesBrown' => 'Janiva::Magness') },
    qr/Cowardly/,
    "Didn't clobber CharlesBrown in coward mode"
);

# Originals
is $Janiva::Magness::var, "Janiva::Magness", "Original: Janiva::Magness";
is $DrMichaelWhite::var, "DrMichaelWhite", "Original: DrMichaelWhite";

# Aliases
is $CharlesBrown::var, "CharlesBrown", "Package CharlesBrown retained";
is $Sharon::Jones::var, "DrMichaelWhite", "Alias: Sharon::Jones";

ok $Janiva::Magness::var
 . $CharlesBrown::var
 . $DrMichaelWhite::var
 . $Sharon::Jones::var, "Silence warnings by using variables once";
