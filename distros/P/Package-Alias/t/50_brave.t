# -*- perl -*-
#
# Tests whether Package::Alias will blow away an existing namespace.
#

#use Test::More tests => 7;
use Test::More qw/no_plan/;
use lib 't/lib';

package Janiva::Magness; $var = "Janiva::Magness";
package CharlesBrown;    $var = "CharlesBrown";

package main;

# Originals
is $CharlesBrown::var, "CharlesBrown", "Original: CharlesBrown";
is $Janiva::Magness::var, "Janiva::Magness", "Original: Janiva::Magness";

BEGIN { $Package::Alias::BRAVE = 1 }
is $Package::Alias::BRAVE, 1, "brave mode is on";

use Package::Alias 'CharlesBrown' => 'Janiva::Magness';

# Aliases
is $CharlesBrown::var, "Janiva::Magness", "Package CharlesBrown successfully clobbered";
is $Janiva::Magness::var, "Janiva::Magness", "Package Janiva::Magness not changed";

ok $Janiva::Magness::var
 . $CharlesBrown::var, "Silence warnings by using variables once";
