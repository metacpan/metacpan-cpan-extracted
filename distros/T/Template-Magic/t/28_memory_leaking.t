; use strict
; use Test::More tests => 1

; use Template::Magic

; $My::Test = 'A'


; sub Template::Magic::DESTROY
   { $My::Test .= 'B'
   }
   
; our $my_loop = [ { date      => '8-2-02'
                   , operation => 'purchase'
                   }
                 , { date      => '9-3-02'
                   , operation => 'payment'
                   }
                 ]
; { my $tm = new Template::Magic
  ; my $tmp = '{my_loop}{date}{operation}{/my_loop}'
  ; my $content = $tm->output(\$tmp);
}


; $My::Test .= 'C'

; is( $My::Test
    , 'ABC'
    , 'Memory leaking test'
    )
