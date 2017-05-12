# test load of package

; use strict
; use Test::More tests => 5

; my $psn

# 01
; BEGIN { $psn = 'Package::Subroutine::Namespace'
         ; use_ok('Package::Subroutine::Namespace')
         }

; package W
; sub one { 1 }

; package W::Q
; sub two { 2 }

; package W::R::P
; sub three { 3 }

; package main

; BEGIN
     { is_deeply([sort $psn->list_childs('W')],['Q','R'],'list childs')
     ; $psn->delete_childs('W')
     ; is_deeply([$psn->list_childs('W')],[],'childs deleted')
     }

; package W::Q
; sub two { 2 }

; package W::R::P
; sub three { 3 }

; package main

; BEGIN
    { $psn->delete_childs('W','R')
    ; is_deeply([$psn->list_childs('W')],['R'],'delete but keep one')
    }

; is(W::one,1,'test "one" in W')

