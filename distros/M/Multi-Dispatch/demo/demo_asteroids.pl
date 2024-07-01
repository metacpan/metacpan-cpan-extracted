#! /usr/bin/env perl

use 5.038;
use warnings;

use Multi::Dispatch;
use Object::Pad;

class Thing {
    method AUTOLOAD { ref($self), (our $AUTOLOAD) =~ s{[^:]+::}{}r; }
    method DESTROY {}
    method shielded {0}
}
class Asteroid   : isa(Thing) {}
class Craft      : isa(Thing) {}
class Ship       : isa(Craft) {}
class ShieldShip : isa(Ship)  { method shielded {1} }
class Saucer     : isa(Craft) {}
class Missile    : isa(Thing) {}

sub scollide ($thing1, $thing2, %opt) {
    $thing1 isa 'Asteroid' && $thing2 isa 'Asteroid' ? ($thing1->split,   $thing2->split  )
  : $thing1 isa 'Asteroid' && $thing2 isa 'Missile'  ? ($thing1->split,   $thing2->explode)
  : $thing1 isa 'Craft'    && $thing2 isa 'Craft'    ? ($thing1->explode, $thing2->explode)
  : $thing1 isa 'Asteroid' && $thing2 isa 'Craft'    ? ($thing1->split,   $thing2->explode)
  : $thing1 isa 'Missile'  && $thing2->shielded      ? ($thing1->explode, $thing2->bounce )
  : $thing1 isa 'Craft'    && $thing2->shielded      ? ($thing1->bounce,  $thing2->bounce )
  : !$opt{swap}                                      ? scollide($thing2,   $thing1, swap=>1)
  :                                                    ($thing1->explode, $thing2->explode)
}

sub tcollide ($thing1, $thing2) {

    $thing1 isa 'Asteroid' && $thing2 isa 'Asteroid' ? ($thing1->split,   $thing2->split  )
  : $thing1 isa 'Asteroid' && $thing2 isa 'Missile'  ? ($thing1->split,   $thing2->explode)
  : $thing1 isa 'Missile'  && $thing2 isa 'Asteroid' ? ($thing1->explode, $thing2->split  )
  : $thing1 isa 'Craft'    && $thing2 isa 'Craft'    ? ($thing1->explode, $thing2->explode)
  : $thing1 isa 'Asteroid' && $thing2 isa 'Craft'    ? ($thing1->split,   $thing2->explode)
  : $thing1 isa 'Craft'    && $thing2 isa 'Asteroid' ? ($thing1->explode, $thing2->split  )
  : $thing1 isa 'Missile'  && $thing2->shielded      ? ($thing1->explode, $thing2->bounce )
  : $thing1->shielded      && $thing2 isa 'Missile'  ? ($thing1->bounce,  $thing2->explode)
  : $thing1 isa 'Ship'     && $thing2->shielded      ? ($thing1->bounce,  $thing2->bounce )
  : $thing1->shielded      && $thing2 isa 'Ship'     ? ($thing1->bounce,  $thing2->bounce )
  :                                                    ($thing1->explode, $thing2->explode)
}

multi mcollide :permute (Asteroid $a1,       Asteroid $a2)  { $a1->split,     $a2->split     }
multi mcollide :permute (Asteroid $a,               $obj )  { $a->split,      $obj->explode  }
multi mcollide :permute (Ship $s->shielded,         $obj )  { $s->bounce,     $obj->bounce   }
multi mcollide :permute (Ship $s->shielded,  Missile  $m )  { $s->bounce,     $m->explode    }
multi mcollide :permute (     $obj1,               $obj2 )  { $obj1->explode, $obj2->explode }


my $as = Asteroid->new;
my $sa = Saucer->new;
my $sh = Ship->new;
my $ss = ShieldShip->new;
my $mi = Missile->new;

sub expect( $obj1, $obj2, $result ) {
    is_deeply( { scollide($obj1, $obj2) }, $result => 'scollide: ' . ref($obj1) . ' vs ' . ref($obj2) );
    is_deeply( { tcollide($obj1, $obj2) }, $result => 'tcollide: ' . ref($obj1) . ' vs ' . ref($obj2) );
    is_deeply( { mcollide($obj1, $obj2) }, $result => 'mcollide: ' . ref($obj1) . ' vs ' . ref($obj2) );
}

use Test::More;

expect( $as, $as, { Asteroid => 'split',  Asteroid   => 'split'   } );
expect( $as, $sa, { Asteroid => 'split',  Saucer     => 'explode' } );
expect( $as, $sh, { Asteroid => 'split',  Ship       => 'explode' } );
expect( $as, $ss, { Asteroid => 'bounce', ShieldShip => 'bounce'  } );
expect( $as, $mi, { Asteroid => 'split',  Missile    => 'explode' } );

expect( $sa, $as, { Saucer => 'explode', Asteroid   => 'split'   } );
expect( $sa, $sa, { Saucer => 'explode', Saucer     => 'explode' } );
expect( $sa, $sh, { Saucer => 'explode', Ship       => 'explode' } );
expect( $sa, $ss, { Saucer => 'bounce',  ShieldShip => 'bounce'  } );
expect( $sa, $mi, { Saucer => 'explode', Missile    => 'explode' } );

expect( $sh, $as, { Ship => 'explode', Asteroid   => 'split'   } );
expect( $sh, $sa, { Ship => 'explode', Saucer     => 'explode' } );
expect( $sh, $sh, { Ship => 'explode', Ship       => 'explode' } );
expect( $sh, $ss, { Ship => 'bounce',  ShieldShip => 'bounce'  } );
expect( $sh, $mi, { Ship => 'explode', Missile    => 'explode' } );

expect( $ss, $as, { ShieldShip => 'bounce', Asteroid   => 'bounce'  } );
expect( $ss, $sa, { ShieldShip => 'bounce', Saucer     => 'bounce'  } );
expect( $ss, $sh, { ShieldShip => 'bounce', Ship       => 'bounce'  } );
expect( $ss, $ss, { ShieldShip => 'bounce', ShieldShip => 'bounce'  } );
expect( $ss, $mi, { ShieldShip => 'bounce', Missile    => 'explode' } );

expect( $mi, $as, { Missile  => 'explode', Asteroid   => 'split'   } );
expect( $mi, $sa, { Missile  => 'explode', Saucer     => 'explode' } );
expect( $mi, $sh, { Missile  => 'explode', Ship       => 'explode' } );
expect( $mi, $ss, { Missile  => 'explode', ShieldShip => 'bounce'  } );
expect( $mi, $mi, { Missile  => 'explode', Missile    => 'explode' } );

done_testing();
