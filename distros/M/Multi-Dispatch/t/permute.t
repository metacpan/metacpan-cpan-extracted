use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 49;

use Multi::Dispatch;

BEGIN { package Thing; }
BEGIN { package DerThing;   our @ISA = 'Thing';    }
BEGIN { package ReDerThing; our @ISA = 'DerThing'; }
BEGIN { package Other; }

multi foo  :permute (Thing $x, Thing $y,      Other $z )           { return 'TTO' }
multi foo  :permute (Thing $x, DerThing $y,   Other $z, $etc = 0 ) { return 'TDO' }
multi foo  :permute (Thing $x, ReDerThing $y, Other $z )           { return 'TRO' }

my $thing      = bless {}, 'Thing';
my $derthing   = bless {}, 'DerThing';
my $rederthing = bless {}, 'ReDerThing';
my $other      = bless {}, 'Other';

is foo($thing,      $thing,      $other), 'TTO' => 'foo($thing,      $thing,      $other)';
is foo($thing,      $derthing,   $other), 'TDO' => 'foo($thing,      $derthing,   $other)';
is foo($thing,      $rederthing, $other), 'TRO' => 'foo($thing,      $rederthing, $other)';
is foo($thing,      $thing,      $other), 'TTO' => 'foo($thing,      $thing,      $other)';
is foo($derthing,   $thing,      $other), 'TDO' => 'foo($derthing,   $thing,      $other)';
is foo($rederthing, $thing,      $other), 'TRO' => 'foo($rederthing, $thing,      $other)';

is foo($other, $thing,      $thing     ), 'TTO' => 'foo($other, $thing,      $thing      )';
is foo($other, $thing,      $derthing  ), 'TDO' => 'foo($other, $thing,      $derthing   )';
is foo($other, $thing,      $rederthing), 'TRO' => 'foo($other, $thing,      $rederthing )';
is foo($other, $thing,      $thing     ), 'TTO' => 'foo($other, $thing,      $thing      )';
is foo($other, $derthing,   $thing     ), 'TDO' => 'foo($other, $derthing,   $thing      )';
is foo($other, $rederthing, $thing     ), 'TRO' => 'foo($other, $rederthing, $thing      )';

is foo($thing,      $other, $thing     ), 'TTO' => 'foo($thing,      $other, $thing      )';
is foo($thing,      $other, $derthing  ), 'TDO' => 'foo($thing,      $other, $derthing   )';
is foo($thing,      $other, $rederthing), 'TRO' => 'foo($thing,      $other, $rederthing )';
is foo($thing,      $other, $thing     ), 'TTO' => 'foo($thing,      $other, $thing      )';
is foo($derthing,   $other, $thing     ), 'TDO' => 'foo($derthing,   $other, $thing      )';
is foo($rederthing, $other, $thing     ), 'TRO' => 'foo($rederthing, $other, $thing      )';

is foo($thing,    $derthing, $other,    'etc'), 'TDO' => 'foo($thing,    $derthing, $other,    etc)';
is foo($derthing, $thing,    $other,    'etc'), 'TDO' => 'foo($derthing, $thing,    $other,    etc)';
is foo($other,    $thing,    $derthing, 'etc'), 'TDO' => 'foo($other,    $thing,    $derthing, etc)';
is foo($other,    $derthing, $thing,    'etc'), 'TDO' => 'foo($other,    $derthing, $thing,    etc)';
is foo($thing,    $other,    $derthing, 'etc'), 'TDO' => 'foo($thing,    $other,    $derthing, etc)';
is foo($derthing, $other,    $thing,    'etc'), 'TDO' => 'foo($derthing, $other,    $thing,    etc)';


BEGIN { package Target;
    sub new      { bless {}, shift }
    sub AUTOLOAD { our $AUTOLOAD; ref(shift), $AUTOLOAD =~ s{[^:]+::}{}r; }
    sub shielded {0}
    sub DESTROY  {}
}
BEGIN { package Asteroid  ; our @ISA = 'Target'; }
BEGIN { package Craft     ; our @ISA = 'Target'; }
BEGIN { package Ship      ; our @ISA = 'Craft';  }
BEGIN { package ShieldShip; our @ISA = 'Ship';  sub shielded {1} }
BEGIN { package Saucer    ; our @ISA = 'Craft';  }
BEGIN { package Missile   ; our @ISA = 'Target'; }


multi collide :permute (Asteroid $a1,       Asteroid $a2)  { $a1->split,    $a2->split   }
multi collide :permute (Asteroid $a,        Target    $t )  {  $a->split,     $t->explode }
multi collide :permute (Target   $t1,       Target   $t2)  { $t1->explode,  $t2->explode }
multi collide :permute (Ship $s->shielded,  Target    $t )  {  $s->bounce,    $t->bounce  }
multi collide :permute (Ship $s->shielded,  Missile  $m )  {  $s->bounce,    $m->explode }

my $as =   Asteroid->new;
my $sa =     Saucer->new;
my $sh =       Ship->new;
my $ss = ShieldShip->new;
my $mi =    Missile->new;

sub expect {
    my ( $obj1, $obj2, $result ) = @_;
    is_deeply( {  collide($obj1, $obj2) }, $result => ' collide: ' . ref($obj1) . ' vs ' . ref($obj2) );
}

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
