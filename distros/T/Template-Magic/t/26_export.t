#!perl -w

; use strict
; use Test::More tests => 2
; use Template::Magic::HTML

; use Template::Magic::HTML
    qw| NEXT_HANDLER
        LAST_HANDLER
      |

; is( LAST_HANDLER
    , 1
    )
; is( NEXT_HANDLER
    , 0
    )
