#!perl -w
; use strict
; use warnings



; package a
; sub test{ __PACKAGE__ }


; package b
; sub test{ __PACKAGE__ }
; our @ISA = qw| x |


; package c
; sub test{ __PACKAGE__ }


; package d
; sub test{ __PACKAGE__ }
; our @ISA = qw| a |


; package e
; sub test{ __PACKAGE__ }
; our @ISA = qw| a b c |

; package f
; sub test{ __PACKAGE__ }
; our @ISA = qw| d e |

; package x
; sub test{ __PACKAGE__ }


; package main
; our @ISA = qw|f|

; use Test::More tests => 3
#; use Data::Dumper
; BEGIN
   { use_ok 'Class::Util'
   ; Class::Util->import('classes')
   }

; use Class::Util qw(classes)

; is join('', classes('f')), 'cxbeadf'
; is join('', classes(bless {},'f')), 'cxbeadf'



__END__

         x
         |
       a b c
      / \|/
     d   e
      \ /
       f


