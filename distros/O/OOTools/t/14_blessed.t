#!perl -w
; use strict
; use warnings
; use Test::More tests => 8
#; use Data::Dumper

; BEGIN
   { use_ok 'Class::Util'
   ; Class::Util->import('blessed')
   }


; is blessed(bless {}, 'aclass'), 'aclass'
; is blessed(undef), undef
; is blessed(''), undef
; is blessed('something'), undef
; is blessed(\'something'), undef
; is blessed({}), undef

; $_ = bless {}, 'aclass'
; is blessed, 'aclass'
