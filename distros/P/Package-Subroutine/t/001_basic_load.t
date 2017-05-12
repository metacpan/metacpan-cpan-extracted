# test load of package

; use strict
; use Test::More tests => 6
; use lib 't/lib'
; use Tags

# 01
; BEGIN { use_ok('Package::Subroutine','Tags','minze') }

# 02
; my $r=eval { minze() }
; ok(!$@)

# 03
; is($r,'blatt')

# 04-06
; my $ref
; ok($ref=isdefined Package::Subroutine 'Tags' => 'minze')
; ok(! isdefined Package::Subroutine 'Tags' => 'eukalyptus')
; is($ref->(),'blatt')
