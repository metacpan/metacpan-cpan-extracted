#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic


; our ( $tm
      , $content
      , $tmp
      , $my_loop
      )

; $tm = new Template::Magic
; $tmp = 'A loop:{my_loop}|Date: {date} - Operation: {operation}{/my_loop}|';

; $content = $tm->output(\$tmp);
; is ($$content
     , 'A loop:|Date: 8-2-02 - Operation: purchase|Date: 9-3-02 - Operation: payment|'
     )

; sub my_loop
   { my ($z) = @_ ;
   ; while ( <DATA> ) # for each line of the file
      { chomp
      ; my $line_hash
      ; @$line_hash{ 'date'
                   , 'operation'
                   }
                   = split /\|/  # create line hash
      ; $z->value = $line_hash                         # set the zone value
      ; $z->value_process()                            # process the value
      }
   }

__DATA__
8-2-02|purchase
9-3-02|payment
