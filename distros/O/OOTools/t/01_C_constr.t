#!perl -w
; use strict
; use Test::More tests => 2


; common_test('BaseClass');
; common_test('SubClass');

; sub common_test
   { my ($class) = @_
   ; $class->N_init_constr
   ; is( $BaseClass::N_init
       , 1
       , 'New custom init'
       )


   }


; package BaseClass

; use Class::constr


; use Class::constr { name => 'N_init_constr'
                    , init => 'N_init'
                    }
                    
; sub N_init { $BaseClass::N_init = 1 }

                                 
; package SubClass
; use base 'BaseClass'
