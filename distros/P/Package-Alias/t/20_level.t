# -*- perl -*-
#
# Tests basic usage with multi-level namespaces (they have ::s in them)
#

use Test::More tests => 5;
#use Test::More qw/no_plan/;

package Janiva::Magness; $var = "Janiva::Magness";
package DrMichaelWhite; $var = "DrMichaelWhite";

package main;
use lib 't/lib';

use Package::Alias 
    'CharlesBrown' => 'Janiva::Magness',
    'EttaJames::FreddieKing' => 'DrMichaelWhite';

# Originals
is $Janiva::Magness::var,	"Janiva::Magness", "Original: Janiva::Magness";
is $DrMichaelWhite::var, "DrMichaelWhite", "Original: DrMichaelWhite";

# Aliases
is $CharlesBrown::var, "Janiva::Magness", "Alias: CharlesBrown";
is $EttaJames::FreddieKing::var, "DrMichaelWhite", "Alias: EttaJames::FreddieKing";

ok $Janiva::Magness::var
 . $CharlesBrown::var
 . $DrMichaelWhite::var
 . $EttaJames::FreddieKing::var, "Silence warnings by using variables once";
