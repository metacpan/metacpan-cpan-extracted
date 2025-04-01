
; use strict; use warnings
; use Test::Warnings ()

; package T::Sugar
; use Test::More tests => 6

; use lib './t/lib'
; use Tags

; BEGIN
    { use_ok('Package::Subroutine::Sugar')
    ; eval { import from:: 'Tags' => 'minze' }
    ; ok(!$@,'import seems to succed in BEGIN block')
    }

; ok(T::Sugar->can('minze'),'import succeeds, proved')

; package T::good

; no Package::Subroutine::Sugar

# interesting: for the import method it is not an error, but on newer perls
# it emits a warning
; my $warn = Test::Warnings::warning { import from::('Tags' => 'minze') };
; if( ref($warn) eq "ARRAY" )
    { if( @$warn == 0 )
        { Test::More::pass("No warning on older perls") }
      else
        { Test::More::fail("Unknown warning?\n" . join("\n",@$warn)) }
    }
  else
    { Test::More::like( $warn, 
         qr/^Attempt to call undefined import method with arguments/,
         "Calling import with unknown module gives a warning.")
    }
; Test::More::ok(!T::good->can('minze'),'import from does nothing now')
 
