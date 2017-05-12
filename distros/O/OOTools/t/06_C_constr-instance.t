#!perl -w

#----------------------------------------------------------------------
# Main package conducts the tests. See below for class definitions.
#----------------------------------------------------------------------
; use strict
; use Test::More tests =>12 

#
# Create a base object (these pass in 1.74)
#
; my ($base, $constructed, $copied)
; isa_ok( $base = BaseClass->new(base_test => 1),  'BaseClass', 'new')
; is( $base->{init_test} , undef , 'base init not run')
; is( $base->{base_test} , 1 , 'base constructor params')

#
# Construct a new object from the existing one, no copy
#
; isa_ok( $constructed = $base->construct(),  'BaseClass', 'construct')
; is( $constructed->{init_test} , 1 , 'constructed init')
; is( $constructed->{base_test} , undef , 'constructed no copy')

#
# Construct a new object from the existing one, with copy
#
; isa_ok( $copied = $base->copy,  'BaseClass', 'copy')
; is( $copied->{init_test} , undef , 'copied no init')
; is( $copied->{base_test} , 1 , 'copied gets values')

#
# Construct a new object from the existing one, with copy & init
#
; $constructed->init_test(2)
; $constructed->base_test(2)
; isa_ok( $copied = $constructed->copy_init(base_test => 1),  'BaseClass', 'newcopy')
; is( $copied->{init_test} , 1 , 'newcopy init overwrites copied val')
; is( $copied->{base_test} , 1 , 'newcopy argument overwrites copied value')



#----------------------------------------------------------------------
# Define classes for this test.
#----------------------------------------------------------------------
; package BaseClass
; use Class::constr
; use Class::constr
   ( { name => 'construct'
     , init => '_init'
     }
   , { name => 'copy',
     , copy => 1
     }
   , { name => 'copy_init',
     , init => '_init'
     , copy => 1
     }
   )               
; use Object::props qw/ base_test init_test /

; sub _init { $_[0]->init_test(1) }
                                 
# vim:ft=perl:expandtab:ts=3:sw=3:
