# test load of package

; use Test2::V0
; BEGIN { plan(5) }

; my $psn
; use Package::Subroutine::Namespace

# 01
; BEGIN { $psn = 'Package::Subroutine::Namespace' }

; package W
; sub one { 1 }

; package W::Q
; sub two { 2 }

; package W::R::P
; sub three { 3 }

; package main

; BEGIN
    { is([sort $psn->list_namespaces('W')],['Q','R'],'list namespaces')
    ; $psn->delete_namespaces('W')
    ; is([$psn->list_namespaces('W')],[],'namespaces deleted')
    }

; package W::Q
; sub two { 'two' }

; package W::R::P
; sub three { 'three' }

; package main

; $psn->delete_namespaces('W','R')
; is([$psn->list_namespaces('W')],['R'],'delete but keep one')


; is(W::one,1,'test "one" in W')
; is(W::Q::two,'two',"calling recreated method")

