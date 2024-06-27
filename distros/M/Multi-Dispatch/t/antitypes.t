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

multi foo( $desc,  !MyClass     $x )  { is 'NMCL',  $desc => '!MyClass';    }
multi foo( $desc,  !MyDerClass  $x )  { is 'NMDC',  $desc => '!MyDerClass'; }
multi foo( $desc,               $x )  { is 'DEF',   $desc => '<typeless>';  }


foo( 'NMDC', bless {}, 'MyClass' );
foo( 'DEF',  bless {}, 'MyDerClass' );


multi bar( $desc, !ARRAY $x ) { is 'NARR', $desc => '!ARRAY'; }
multi bar( $desc,        $x ) { is 'DEF',  $desc => 'DEF';    }

bar( 'NARR', {} );
bar( 'DEF',  [] );


multi baz( $desc, !Num $x ) { is 'NNUM', $desc => '!Num';     }
multi baz( $desc,      $x ) { is 'DEF',  $desc => 'DEF'; }

baz( 'NNUM', 'a' );
baz( 'DEF',   1  );


done_testing();

