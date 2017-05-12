# -*- perl -*-
#
# Tests basic usage with single-level namespaces (no ::s in them)
#

use Test::More tests => 9;
#use Test::More qw/no_plan/;
use lib 't/lib';

package AlGreen; $var = "AlGreen";
package CharlesBrown; $var = "CharlesBrown";
package KaraGrainger; $var = "KaraGrainger";
package Maceo; $var = "Maceo";

package main;

use Package::Alias BrotherYusef => AlGreen;
use Package::Alias DrMichaelWhite => CharlesBrown;
use Package::Alias Lhasa => KaraGrainger,
    NinaSimone => Maceo;

# Originals
is $AlGreen::var, "AlGreen", "Original: AlGreen";
is $CharlesBrown::var, "CharlesBrown", "Original: CharlesBrown";
is $KaraGrainger::var, "KaraGrainger", "Original: KaraGrainger";
is $Maceo::var, "Maceo", "Original: Maceo";

# Aliases
is $BrotherYusef::var, "AlGreen", "Alias: BrotherYusef";
is $DrMichaelWhite::var, "CharlesBrown", "Alias: DrMichaelWhite";

# More than one package aliased in one call
is $Lhasa::var, "KaraGrainger", "Alias: Lhasa";
is $NinaSimone::var, "Maceo", "Alias: NinaSimone";

ok $AlGreen::var
 . $BrotherYusef::var
 . $CharlesBrown::var
 . $DrMichaelWhite::var
 . $KaraGrainger::var
 . $Lhasa::var
 . $Maceo::var
 . $NinaSimone::var, "Silence warnings by using each variables once";