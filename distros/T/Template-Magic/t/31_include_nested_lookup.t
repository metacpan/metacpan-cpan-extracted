#!perl -w
; use strict
; use Test::More tests => 4
                    
; package MyClass
; sub my_method {'my method'}
; sub a_block{ return {} }

; package main
; use Template::Magic
; chdir './t'

; my $t1 = 'start {the_class}{a_block}# {my_method} #{/a_block}{/the_class} end'
; my $t2 = 'start {the_class}{INCLUDE_TEMPLATE included_test_03}{/the_class} end'
; my $o = Template::Magic->new()
; my $the_class1 = bless {} => 'MyClass'
; my $the_class2 = { my_method => sub{'my method'}
                   , a_block => {}
                   }


; is ${$o->output(\ $t1, {the_class => $the_class1} )}, 'start # my method # end'
; is ${$o->output(\ $t1, {the_class => $the_class2} )}, 'start # my method # end'
; is ${$o->output(\ $t2, {the_class => $the_class1} )}, 'start # my method # end'
; is ${$o->output(\ $t2, {the_class => $the_class2} )}, 'start # my method # end'






       
