#!perl -w
; use strict
; use warnings
; use Test::More tests => 20
#; use Data::Dumper

; BEGIN
   { use_ok 'Class::Error'
   }


; eval{ Class::Error->new('errstr', 500, 1) }
; ok $@, 'Constructor dies on true arguments'

   
; my $o_undef = Class::Error->new('errstr', 500)

; isa_ok $o_undef, 'Class::Error'
; ok defined $o_undef, 'The object is defined'


; { no warnings
  ; is "$o_undef", '', 'The object is undef in string context'
  }
  
; is do{'ok' unless $o_undef}, 'ok', 'The object is false in boolean context'

; my $res = $o_undef->any_method('a', 'b')->any_other_method
; isa_ok $res, 'Class::Error', 'The result of methods'

; is ($o_undef->errnum, 500, '(object) The error number is ok')
; is (Class::Error->errnum, 500, '(class) The error number is ok')
; is ($o_undef->error, 'errstr', '(object) The error string is ok')
; is (Class::Error->error, 'errstr', '(class) The error string is ok')

; my $o_empty = Class::Error->new('errstr', 500, '')

; isa_ok $o_empty, 'Class::Error'
; ok defined $o_empty, 'The object is defined'

  
; is do{'ok' unless $o_empty}, 'ok', 'The object is false in boolean context'

; $res = $o_empty->any_method('a', 'b')->any_other_method
; isa_ok $res, 'Class::Error', 'The result of methods'

; my $o_zero = Class::Error->new('errstr', 500, 0)

; isa_ok $o_zero, 'Class::Error'
; ok defined $o_zero, 'The object is defined'

; is $o_zero + 2, 2, 'The object is 0 in numeric context'
  

; is do{'ok' unless $o_zero}, 'ok', 'The object is false in boolean context'

; $res = $o_zero->any_method('a', 'b')->any_other_method
; isa_ok $res, 'Class::Error', 'The result of methods'






