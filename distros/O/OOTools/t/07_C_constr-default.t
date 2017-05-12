#!perl -w
; use strict
; use warnings
; use Test::More tests => 6
#; use Data::Dumper

; package My::Test1

; use Class::constr
   { default => { a => 2
                , b => 3
                }
   , no_strict => 1
   }


; package main
; is_deeply ( scalar My::Test1->new()
            , { a => 2
              , b => 3
              }
            )


; package My::Test2

; use Class::constr
   { default => sub{ +{ a => 2
                      , b => 3
                      }
                   }
   , no_strict => 1
   }


; package main
; is_deeply ( scalar My::Test2->new()
            , { a => 2
              , b => 3
              }
            )

; package My::Test3

; use Class::constr
   { default => 'def'
   , no_strict => 1
   }

; sub def
   { +{ a => 2
      , b => 3
      }
   }
   
; package main
; is_deeply ( scalar My::Test3->new()
            , { a => 2
              , b => 3
              }
            )
            
; package My::Test4

; use Class::constr
   { default => sub{ +{ a => 2
                      , b => 3
                      }
                   }
   , no_strict => 1
   }


; package main
; is_deeply ( scalar My::Test2->new(a=>5)
            , { a => 5
              , b => 3
              }
            )

# overwriting

; package My::Test5

; use Class::constr
   { default => { a => 2
                , b => 3
                }
   , no_strict => 1
   }
   
; use Class::constr
   { name    => 'copy_me'
   , default => { a => 4
                , b => 5
                , c => 5
                }
   , copy    => 1
   , no_strict => 1
   }
   
; package main
; my $o = My::Test5->new()
; is_deeply ( $o
            , { a => 2
              , b => 3
              }
            )
            
; is_deeply ( scalar $o->copy_me(a=>8)
            , { a => 8
              , b => 3
              , c => 5
              }
            )












