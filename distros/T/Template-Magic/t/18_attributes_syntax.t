#!perl -w

; use strict;
; use Test::More tests => 1;
; use Template::Magic

; our ( $id
      , $tm
      , $tmp
      , $expected
      , $content
      )
      
; $id = 15;
; $tm = new Template::Magic
        zone_handlers => sub
                          { my ($z) = @_;
                          ; if ($z->id eq '_custom_')
                             { $z->value = $z->attributes;
                             ; return undef ;
                             }
                          }

; $tmp = <<'EOS';
text {_custom_ 
        key => value, value2}text{/_custom_} text {id} text
EOS

; $expected = <<'EOE';
text  
        key => value, value2 text 15 text
EOE

; $content = $tm->output(\$tmp)
; is ( $$content
     , $expected
     )
