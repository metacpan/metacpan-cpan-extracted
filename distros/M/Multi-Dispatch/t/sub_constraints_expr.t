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
        plan tests => 15;
    }
}


use Multi::Dispatch;

multi foo  ($x    , $y    ) { return '??' }
multi foo  ($x > 0, $y    ) { return '+?' }
multi foo  ($x > 0, $y < 0) { return '+-' }

is foo(+1, -1), '+-' => 'foo(+-)';
is foo(+1, +1), '+?' => 'foo(++)';
is foo(-1, -1), '??' => 'foo(--)';


multi bar (Num $x                      )  { return 'num' }
multi bar (Num $x < 0                  )  { return 'negative num' }
multi bar (Num $x < 0 :where({$x % 2}) )  { return 'negative odd num' }
multi bar (Int $x > 0 :where(/7/)      )  { return 'positive int with seven' }

is bar(127),  'positive int with seven' => 'bar(127)';
is bar(-99),  'negative odd num'        => 'bar(-99)';
is bar(-8.6), 'negative num'            => 'bar(-8.6)';
is bar(42),   'num'                     => 'bar(42)';

use experimental 'postderef';

multi baz ($x % 2)                { 'odd'        }
multi baz ($x < 0)                { 'negative'   }
multi baz ($x > 0)                { 'positive'   }
multi baz ($x == 0)               { 'neutral'    }
multi baz (ARRAY $x->$#* >= 0)    { 'non-empty'  }
multi baz (ARRAY $x->@*  == 0)    { 'empty'      }
multi baz ($y =~ /\d/, $x > $y)   { 'increasing' }
multi baz ($ID, $x->{ID} eq $ID)  { 'ID match'   }

use Test::More;

is baz(-2),              'negative'    =>  'baz negative'  ;
is baz(+2),              'positive'    =>  'baz positive'  ;
is baz(+1),              'odd'         =>  'baz odd'       ;
is baz( 0),              'neutral'     =>  'baz neutral'   ;
is baz([1]),             'non-empty'   =>  'baz non-empty' ;
is baz([]),              'empty'       =>  'baz empty'     ;
is baz(1,2),             'increasing'  =>  'baz increasing';
is baz('a',{ID => 'a'}), 'ID match'    =>  'baz ID match'  ;

done_testing();
