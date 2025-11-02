# test load of package

; use Test2::V0

; use lib 't/lib'
; use Tags

; BEGIN { plan(5) }

; use Package::Subroutine 'Tags' => 'minze'

; my $r=eval { minze() }
; ok(!$@)

# 03
; is($r,'blatt')

# 04-06
; my $ref
; ok($ref=isdefined Package::Subroutine 'Tags' => 'minze')
; ok(! isdefined Package::Subroutine 'Tags' => 'eukalyptus')
; is($ref->(),'blatt')
