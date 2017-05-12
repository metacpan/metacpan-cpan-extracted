use 5.010;
use warnings;

use Perl6::Form;

$floor_plan = <<EOPLAN;
################################
#                         #  # #
######################### # ## #
#                              #
# #   # #   ###  ##   ######## #
# ##### ###  #  ##    #   #  # #
#       # ##   ##       #    # #
### #####  ############## #### #
#                              #
################################
EOPLAN

$legend = <<'EOLEGEND';
# - Wall
* - Gold
@ - You
^ - Trap
@ - Stairs
$ - Bank
& - Statue
! - Potion
( - Sword
{ - Bow
= - Door
| = Wand
EOLEGEND

print form
    {page=>{length=>24}, fill=>'#'},
    '{=]]]]{*}[[[[=}## {="{*}"=} ##',
    $floor_plan,      {hfill=>' '},
                      $legend;



