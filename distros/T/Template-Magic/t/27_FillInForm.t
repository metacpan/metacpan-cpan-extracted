#!perl -w

; use strict
; use Test::More tests => 2
; use Template::Magic
; use Template::Magic::HTML
; use CGI

; our $FillInForm = CGI->new( { fieldA => 'A'
                              , fieldB => 'B'
                              , fieldC => 'C'
                              }
                            )


; my $temp1 = << "EOT1"
<!--{FillInForm ignore_fields => [ 'fieldA', 'fieldC' ] }-->
<form>
<input type= "text" name="fieldA">
<input type= "text" name="fieldB">
<input type= "text" name="fieldC">
</form>
<!--{/FillInForm}-->
EOT1


; my $temp2 = << "EOT2"
<!--{FillInForm}-->
<form>
<input type= "text" name="fieldA">
<input type= "text" name="fieldB">
<input type= "text" name="fieldC">
</form>
<!--{/FillInForm}-->
EOT2

; my $expected1 = << "EOE1"

<form>
<input name="fieldA" type="text">
<input value="B" name="fieldB" type="text">
<input name="fieldC" type="text">
</form>
EOE1

; my $expected2 = << "EOE2"

<form>
<input value="A" name="fieldA" type="text">
<input value="B" name="fieldB" type="text">
<input value="C" name="fieldC" type="text">
</form>
EOE2

; my $tm = Template::Magic::HTML->new()

; use IO::Util
; SKIP: { skip("HTML::FillInForm is not installed on this system", 2 )
          unless eval
                  { require HTML::FillInForm
                  }

      ; my $filled1 = $tm->output(\$temp1)

      ; is( $$filled1
          , $expected1
          )
      ; my $filled2 = $tm->output(\$temp2)
      ; is( $$filled2
          , $expected2
          )

      }

