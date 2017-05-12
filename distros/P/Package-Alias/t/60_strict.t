# -*- perl -*-
#
# Tests behavior under strict.
#

#use Test::More tests => 5;
use Test::More qw/no_plan/;
use lib 't/lib';

use strict;

$Janiva::Magness::var = "Janiva::Magness";
$DrMichaelWhite::var = "DrMichaelWhite";

use Package::Alias 
    'CharlesBrown' => 'Janiva::Magness',
    'Sharon::Jones' => 'DrMichaelWhite';

# Originals
is $Janiva::Magness::var, "Janiva::Magness", "Original: Janiva::Magness";
is $DrMichaelWhite::var, "DrMichaelWhite", "Original: DrMichaelWhite";

# Aliases
is $CharlesBrown::var, "Janiva::Magness", "Alias: CharlesBrown";
is $Sharon::Jones::var, "DrMichaelWhite", "Alias: Sharon::Jones";

ok $Janiva::Magness::var
 . $CharlesBrown::var
 . $DrMichaelWhite::var
 . $Sharon::Jones::var, "Silence warnings by using variables once";
