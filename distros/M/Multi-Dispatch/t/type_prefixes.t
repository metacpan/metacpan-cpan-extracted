use 5.022;
use warnings;
use strict;

use Test::More;

BEGIN {
    if (! eval {require Types::Standard}) {
        plan skip_all => 'Test required Types::Standard module';
        exit;
    }
    else {
        Types::Standard->import(':all');
    }
}

use Multi::Dispatch;


BEGIN { package MyClass;    sub bar {} }
BEGIN { package MyDerClass; our @ISA = 'MyClass'; sub bar {} }

multi foo( $desc,  Type::Tiny    $x                    )  { is 'Tiny', $desc => 'Type::Tiny';    }
multi foo( $desc,  MyClass       $x                    )  { is 'MCL',  $desc => 'MyClass';       }
multi foo( $desc,  MyDerClass    $x                    )  { is 'MDC',  $desc => 'MyDerClass';    }

multi foo( $desc,  ARRAY         $x                    )  { is 'ARR',  $desc => 'ARRAY';         }
multi foo( $desc,  ArrayRef[Int] $x :where({@$x > 10}) )  { is 'ARI',  $desc => 'ArrayRef[Int]'; }

multi foo( $desc,  Int           $x :where({$x > 10})  )  { is 'I>10', $desc => 'Int, > 10';     }
multi foo( $desc,  Int           $x                    )  { is 'Int',  $desc => 'Int';           }
multi foo( $desc,  Num           $x                    )  { is 'Num',  $desc => 'Num';           }

multi foo( $desc,  Str           $x                    )  { is 'Str',  $desc => 'Str';           }

multi foo( $desc,  Map[Str,Int]  $x                    )  { is 'MSI',  $desc => 'Map[Str,Int]';  }
multi foo( $desc,  HASH          $x                    )  { is 'HSH',  $desc => 'HASH';          }

multi foo( $desc,  SCALAR        $x                    )  { is 'SLR',  $desc => 'SCALAR';        }
multi foo( $desc,  GLOB          $x                    )  { is 'GLB',  $desc => 'GLOB';          }
multi foo( $desc,  REF           $x                    )  { is 'REF',  $desc => 'REF';           }
multi foo( $desc,  REGEXP        $x                    )  { is 'RXP',  $desc => 'REGEXP';        }


foo( 'Tiny', Int     );
foo( 'MCL',  bless {}, 'MyClass' );
foo( 'MDC',  bless {}, 'MyDerClass' );

foo( 'ARI',  [1..11] );
foo( 'ARR',  [1..9]  );

foo( 'I>10', 11      );
foo( 'Int',  10      );
foo( 'Num',  10.1    );

foo( 'Str',  'a10'   );

foo( 'MSI',  {a=>1, b=>2, c=>99 } );
foo( 'HSH',  {a=>1, b=>2, c=>'z' } );

foo( 'SLR',  \my $var1  );
foo( 'REF',  \\my $var2 );
foo( 'GLB',  \*STDOUT   );
foo( 'RXP',  qr{x*}     );


# Test type specificity...

multi bar (Any   $x) { return 'Any'   }
multi bar (Value $x) { return 'Value' }
multi bar (Num   $x) { return 'Num'   }
multi bar (Int   $x) { return 'Int'   }

is bar(1),     'Int'   => 'bar(1)';
is bar(1.1),   'Num'   => 'bar(1.1)';
is bar('a'),   'Value' => "bar('a')";
is bar(undef), 'Any'   => 'bar(undef)';


multi baz(Num $x, Int $y, Int $z) { return 'NII' }
multi baz(Int $x, Num $y, Int $z) { return 'INI' }
multi baz(    $x,     $y, Num $z) { return 'VVN' }
multi baz(Int $x, Int $y, Num $z) { return 'IIN' }

is baz(1,2,3),   'NII' => 'instantiation order breaks ties';
is baz(1,2,3.3), 'IIN' => 'more-typed predominates';


multi arr(Int @n) { return 'I' }
multi arr(Num @n) { return 'N' }
multi arr(Any @n) { return 'A' }

is arr(1..3),      'I' => 'Int @n';
is arr(1..3, 4.4), 'N' => 'Num @n';
is arr(1..3, 'a'), 'A' => 'Any @n';


multi hsh(Int %n) { return 'I' }
multi hsh(Num %n) { return 'N' }
multi hsh(Any %n) { return 'A' }

is hsh(a=>1, b=>2),     'I' => 'Int %n';
is hsh(a=>1, b=>2.2),   'N' => 'Num %n';
is hsh(a=>'a', b=>'b'), 'A' => 'Any %n';



# This was an actual bug (previous returned "ST", not "SM". Now fixed)...

BEGIN { package Thing }
BEGIN { package Asteroid; our @ISA = 'Thing'; }
BEGIN { package Craft;    our @ISA = 'Thing'; }
BEGIN { package Ship;     our @ISA = 'Craft'; }
BEGIN { package Missile;  our @ISA = 'Thing'; }

multi collide (Asteroid $a1, Asteroid $a2)  { return 'AA' }
multi collide (Asteroid $a,  Thing   $t  )  { return 'AT' }
multi collide (Ship $s,      Thing   $t  )  { return 'ST' }
multi collide (Ship $s,      Missile $m  )  { return 'SM' }
multi collide (Thing $t1,    Thing   $t2 )  { return 'TT' }

is collide( bless({}, 'Ship'), bless({},'Missile') ), 'SM'  =>  'Derived before Base';

done_testing();
