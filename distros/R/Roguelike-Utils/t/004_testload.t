use Test::More tests => 2;

#the pupose of this test is to ceck the "area::load" feature

package mymonster;
use base 'Games::Roguelike::Mob';

package myitem;
use base 'Games::Roguelike::Item';

package main;

$map = '
##########
#k.<+..!.#
########.#
#>..D....#
##########
';

%key = (
        'k'=>{class=>'mymonster', type=>'kobold', name=>'Harvey', hd=>12,
              items=>['potion of healing',
                      {class=>'myweapon', name=>'Blue Sword', hd=>9, dd=>4, drain=>1, glow=>1}
                     ]
             },
        '!'=>{lib=>'potion of speed'},
        'D'=>{lib=>'blue dragon', name=>'Charlie', hp=>209},
        '+'=>{color=>'blue'}
       );

%lib = (
        'potion of speed'=>{class=>'myitem', sym=>'!', type=>'potion', effect=>'speed', power=>1},
        'potion of healing'=>{class=>'myitem', sym=>'!', type=>'potion', effect=>'heal', power=>1},
        'blue dragon'=>{class=>'mymonster', sym=>'D', type=>'dragon', breath=>'lightning', hp=>180, hd=>12, at=>[10,5], dm=>[5,10], speed=>5, color=>'cyan'},
       );

use Games::Roguelike::Area;
use Games::Roguelike::Mob;

$a = new Games::Roguelike::Area;

$a->load(map=>$map, key=>\%key, lib=>\%lib);

ok(UNIVERSAL::isa($a->mobat(1,1), 'Games::Roguelike::Mob'), 'loaded mob');
ok($a->map(1,1) eq $a->{fsym}, 'loaded map');


