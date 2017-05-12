
; use strict; use warnings

; package T::Sugar
; use Test::More tests => 4

; use lib './t/lib'
; use Tags

; BEGIN
    { use_ok('Package::Subroutine::Sugar')
    ; eval { import from 'Tags' => 'minze' }
    ; ok(!$@,'import seems to succed in BEGIN block')
    }

; ok(T::Sugar->can('minze'),'import succeeds, proved')

; package T::good

; no Package::Subroutine::Sugar

# interessting - this is not an error
# it seems this function is not executed
; import from('Tags' => 'minze')

; Test::More::ok(!T::good->can('minze'),'import from does nothing now')
 
