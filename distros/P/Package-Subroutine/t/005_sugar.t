

; use Test2::V0

; use lib './t/lib'
; use Package::Subroutine::Sugar

; package T::Sugar

; use Tags

; BEGIN
    { eval { import from:: 'Tags' => 'minze' }
    ; Test2::V0::ok(!$@,'import seems to succeed in BEGIN block')
    }

; Test2::V0::can_ok('T::Sugar','minze')

; package T::good

; no Package::Subroutine::Sugar

# interesting: for the import method it is not an error, but on newer perls
# it emits a warning
; my $warn = Test2::V0::warnings { import from::('Tags' => 'minze') };
if( @$warn == 0 )
    { Test2::V0::pass("No warning on older perls")
    }
else
    { Test2::V0::like( $warn->[0], 
         qr/^Attempt to call undefined import method with arguments/,
         "Calling import with unknown module gives a warning.")
    ; Test2::V0::ok( @$warn == 1, "Only one warning" )
    ; Test2::V0::diag(join("\n",@$warn[1..(scalar(@$warn)-1)])) if @$warn > 1
    }

; Test2::V0::ok(!T::good->can('minze'),'import from does nothing now')

; Test2::V0::done_testing;
 
