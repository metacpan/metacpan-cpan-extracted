use 5.022;
use warnings;
use strict;

use Test::More;

BEGIN {
    if (!eval {require Types::Standard}) {
        plan skip_all => 'Test required Types::Standard module';
        exit;
    }
    else {
        Types::Standard->import(':all');
    }
}

use Multi::Dispatch;

BEGIN { package MyClass; sub bar {} }
BEGIN { package MyDerClass; our @ISA = 'MyClass'; sub bar {} }

multi foo( $desc,  $x :where(Type::Tiny)        )  { is 'Tiny', $desc => 'Type::Tiny';        }
multi foo( $desc,  $x :where(MyClass)           )  { is 'MCL',  $desc => 'MyClass';           }
multi foo( $desc,  $x :where(MyDerClass)        )  { is 'MDC',  $desc => 'MyDerClass';        }
multi foo( $desc,  $x :where(ArrayRef[Int])     )  { is 'ARI',  $desc => 'ArrayRef[Int]';     }
multi foo( $desc,  $x :where(ArrayRef[Num|Ref]) )  { is 'ANR',  $desc => 'ArrayRef[Num|Ref]'; }
multi foo( $desc,  $x :where(ARRAY)             )  { is 'ARR',  $desc => 'ARRAY';             }
multi foo( $desc,  $x :where(Int)               )  { is 'Int',  $desc => 'Int';               }
multi foo( $desc,  $x :where(Num)               )  { is 'Num',  $desc => 'Num';               }
multi foo( $desc,  $x :where(Str)               )  { is 'Str',  $desc => 'Str';               }
multi foo( $desc,  $x :where(Map[Str,Int])      )  { is 'MSI',  $desc => 'Map[Str,Int]';      }
multi foo( $desc,  $x :where(HASH)              )  { is 'HSH',  $desc => 'HASH';              }
multi foo( $desc,  $x :where(SCALAR)            )  { is 'SLR',  $desc => 'SCALAR';            }
multi foo( $desc,  $x :where(GLOB)              )  { is 'GLB',  $desc => 'GLOB';              }
multi foo( $desc,  $x :where(REF)               )  { is 'REF',  $desc => 'REF';               }
multi foo( $desc,  $x :where(REGEXP)            )  { is 'RXP',  $desc => 'REGEXP';            }


foo( 'Tiny', Int     );
foo( 'MCL',  bless {}, 'MyClass' );
foo( 'MDC',  bless {}, 'MyDerClass' );

foo( 'ANR',  [1.1, 2.2, 3.3] );
foo( 'ANR',  [\(1..11)] );
foo( 'ARI',  [1..11] );
foo( 'ARR',  ['a'..'d'] );

foo( 'Int',  10      );
foo( 'Num',  10.1    );

foo( 'Str',  'a10'   );

foo( 'MSI',  {a=>1, b=>2, c=>99 } );
foo( 'HSH',  {a=>1, b=>2, c=>'z' } );

foo( 'SLR',  \my $var1  );
foo( 'REF',  \\my $var2 );
foo( 'GLB',  \*STDOUT   );
foo( 'RXP',  qr{x*}     );


multi bar ($x :where(Int),          $desc) { is $desc, 'Int'  =>  'bar(Int)' }
multi bar ($x :where(~(Int | Ref)), $desc) { is $desc, 'NIR'  =>  'bar(NIR)' }
multi bar ($x,                      $desc) { is $desc, 'Any'  =>  'bar(Any)' }

bar(1   => 'Int');
bar('a' => 'NIR');
bar([]  => 'Any');

done_testing();


