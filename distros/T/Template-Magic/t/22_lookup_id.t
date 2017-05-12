#!perl -w

; use strict
; use Test::More tests => 1
; use Template::Magic


; my $template = << 'EOT' ;
<!--{message}-->
  <!--{part}-->
    <!--{message_size}-->
    <!--{part_nr}-->
    <!--{html}-->
      <!--{message_size}-->
      <!--{part_nr}-->
      <!--{square}-->
    <!--{/html}-->
  <!--{/part}-->
  <!--{message_size}-->
<!--{/message}-->
EOT

; sub message
   { +{ message_size => 42
      , part         => [ map
                           { +{ part_nr => $_
                              }
                           }
                           1..3
                        ]
      }
   }

; sub html
   { my $zone = shift;
   ; my $pnr  = $zone->lookup('part_nr')
   ; +{ square => $pnr * $pnr
      }
   }

; my $tm = new Template::Magic
               markers => 'HTML'

; my $output = $tm->output(\$template)
; $$output =~ s/ /-/g

; my $expected = << 'EOE';

--
----42
----1
----
------42
------1
------1
----
--
----42
----2
----
------42
------2
------4
----
--
----42
----3
----
------42
------3
------9
----
--
--42

EOE

; is( $$output
    , $expected
    )
