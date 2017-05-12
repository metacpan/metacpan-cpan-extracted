#!perl -w
; use strict
; use Test::More tests => 3
; use Template::Magic

; use Carp
; chdir './t'
; our ( $tm
      , $tm2
      , $tm3
      , $tm4
      , $tmp2
      , $tmp3
      , $tmp4
      , $scalar_test
      , $content
      , $content2
      , $content3
      , $content4
      , $content5
      )
; $tm = new Template::Magic

; $scalar_test = 'SCALAR'

; $tm3 = new Template::Magic
             zone_handlers=>'INCLUDE_TEXT'
; $tmp3 = 'text from template {scalar_test}, {INCLUDE_TEXT text_file}'
; $content3 = $tm3->output(\$tmp3);
; is ( $$content3
     , 'text from template SCALAR, text from file {scalar_test}'
     )
; {
; my $tm4 = new Template::Magic
; $tmp4 = 'text from template {scalar_test}, {include_temp}'
; $content4 = $tm4->output(\$tmp4);
}
; is ( $$content4
     , 'text from template SCALAR, text from file SCALAR'
     )
     
; {
; my $tm5 = new Template::Magic
; my $tmp5 = 'text from template {scalar_test}, {INCLUDE_TEMPLATE text_file}'
; $content5 = $tm5->output(\$tmp5);
}
; is ( $$content5
     , 'text from template SCALAR, text from file SCALAR'
     )

; sub include_temp
   { my ($z) = @_
   ; return $z->include_template('text_file')
   }


