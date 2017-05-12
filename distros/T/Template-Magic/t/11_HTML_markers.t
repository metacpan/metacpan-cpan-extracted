#!perl -w

; use strict
; use Test::More tests => 2
; use Template::Magic

; our ( $tm1
      , $tm2
      , $name
      , $surname
      , $content
      , $tmp
      )
; $tm1 = new Template::Magic
             markers => 'HTML'
; $tm2 = new Template::Magic
             markers => [ qw|<!--{ / }-->|
                        ]

; $tmp = '<p><hr>Name: <b><!--{name}-->John<!--{/name}--></b><br>Surname: <b><!--{surname}-->Smith<!--{/surname}--></b><hr></p>'

; $name = 'Domizio'
; $surname = 'Demichelis'

; $content = $tm2->output(\$tmp)

; is( $$content
    , '<p><hr>Name: <b>Domizio</b><br>Surname: <b>Demichelis</b><hr></p>'
    )

; $content = $tm1->output(\$tmp);

; is( $$content
    , '<p><hr>Name: <b>Domizio</b><br>Surname: <b>Demichelis</b><hr></p>'
    )

