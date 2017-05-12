#!perl -w
; use strict
; use warnings
; use Test::More tests => 6
#; use Data::Dumper

; use Class::groups
   { name => 'agroup'
   , default => { a => 1
                , c => 3
                }
   , props => [ { name => 'b'
                , default => 6
                , post_process => sub{$_*2}
                }
              , 'd'
              ]
   , no_strict => 1
   }
   
; use Class::props
   { name => 'e'
   }
   

; my ($b, $c, $d, $e) = main->agroup(['b', 'c', 'd', 'e'])

; is( $b, 12)
; is( $c, 3)
; is( $d, undef)
; ok( exists $main::agroup{d})
; is( $e, undef)
; ok( ! exists $main::agroup{e})


