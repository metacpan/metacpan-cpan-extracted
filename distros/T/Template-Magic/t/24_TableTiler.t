#!perl -w

; use strict
; use Test::More tests => 2
; use Template::Magic
; use Template::Magic::HTML

; our $matrix
; $matrix = [ [ 1.. 5]
            , [ 6..10]
            , [11..15]
            ]


; our $expected = << "__EOT__";
<table border="0" cellspacing="1" cellpadding="3">

<tr>
	<td bgcolor="#9999cc">1</td>
	<td bgcolor="#ccccff">2</td>
	<td bgcolor="#9999cc">3</td>
	<td bgcolor="#ccccff">4</td>
	<td bgcolor="#9999cc">5</td>
</tr>
<tr>
	<td bgcolor="#9999cc">6</td>
	<td bgcolor="#ccccff">7</td>
	<td bgcolor="#9999cc">8</td>
	<td bgcolor="#ccccff">9</td>
	<td bgcolor="#9999cc">10</td>
</tr>
<tr>
	<td bgcolor="#9999cc">11</td>
	<td bgcolor="#ccccff">12</td>
	<td bgcolor="#9999cc">13</td>
	<td bgcolor="#ccccff">14</td>
	<td bgcolor="#9999cc">15</td>
</tr>

</table>
__EOT__

; our $tmp = << "EOT";
<!--{matrix V_TILE H_TILE}--><table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc">placeholder</td>
<td bgcolor="#ccccff">placeholder</td>
</tr>
</table><!--{/matrix}-->
EOT

; our $tm = new Template::Magic::HTML
; our $tm2 = new Template::Magic
                 ( markers        => 'HTML_MARKERS'
                 , value_handlers => [ qw| SCALAR
                                           REF
                                           CODE
                                           TableTiler
                                           ARRAY
                                           HASH
                                           FillInForm
                                         |
                                     ]
                 ) ;
                                       
SKIP: { skip("HTML::TableTiler not installed or not current", 2 )
        unless eval
                { require HTML::TableTiler
                ; $HTML::TableTiler::VERSION >= 1.14
                }

      ; my $tiled_table = $tm->output(\$tmp)
      ; is( $$tiled_table
          , $expected
          )

      ; $tiled_table = $tm2->output(\$tmp )
      ; is( $$tiled_table
          , $expected
          )

      }
