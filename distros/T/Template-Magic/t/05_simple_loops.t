#!perl -w
; use strict 
; use Test::More tests => 1
; use  Template::Magic


; my $tm = new Template::Magic
; my $tmp1 = 'A loop:{my_loop1}|Date: {date} - Operation: {operation}{/my_loop1}|'

; our $my_loop1 = [ { date      => '8-2-02'
                    , operation => 'purchase'
                    }
                  , { date      => '9-3-02'
                    , operation => 'payment'
                    }
                  ]

; my $content1 = $tm->output(\$tmp1);
; is ( $$content1
     , 'A loop:|Date: 8-2-02 - Operation: purchase|Date: 9-3-02 - Operation: payment|'
     )


