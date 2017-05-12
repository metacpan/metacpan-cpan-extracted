#!perl -w

; use strict
; use Test::More tests => 4
; use Template::Magic


      
; my $container1 = 'start {INCLUDE_TEMPLATE } end'
; my $tmp1       = 'included template'
; my $tmp2       = 'included template 2'



; my $tm = Template::Magic->new( container_template => \$container1 )

   
; is ${ $tm->output(\$tmp1) }
   , 'start included template end'
   
; my $container2 = 'start {INCLUDE_TEMPLATE} end 2'


; is ${ $tm->noutput( template           => \$tmp2
                    , container_template => \$container2)
      }
   , 'start included template 2 end 2'

; is ${ $tm->output(\$tmp1) }
   , 'start included template end'


; is $ { $tm->output(\$tmp2) }
   , 'start included template 2 end'
  


