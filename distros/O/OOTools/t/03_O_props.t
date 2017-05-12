#!perl -w
; use strict
; use Test::More tests => 68


; common_test('BaseClass');
; common_test('SubClass');

; sub common_test
   { my ($class) = @_

   ; my $o1 = $class->new
   ; isa_ok( $o1, $class )
   ; $o1->BpropA = 2
   ; $o1->BpropB = 3

   ; my $o2 = $class->new( BpropA => 25
                            , BpropB => 3
                            )
   ; is( $o2->BpropA * $o2->BpropB
       , 75
       , 'Passing new properties with new' )
       
   ; is( $$o2{BpropA} * $$o2{BpropB}
       , 75
       , 'Passing new properties with new (underlaying scalar check)' )
       
   ; is( $o1->BpropA * $o1->BpropB
       , 6
       , 'Other object same test' )

   ; is( $$o1{BpropA} * $$o1{BpropB}
       , 6
       , 'Other object same test (underlaying scalar check)' )

   ; eval
      { my $o3 = $class->new( unknown => 10 )
      }
   ; ok( $@
       , 'Passing an unknow property'
       )
    
   ; eval
      { my $o3 = $class->new( Bprot => 10 )
      }
   ; ok( $@
       , 'Passing a value to a protected property'
       )

   ; is( $o1->Bdefault
       , 25
       , "Reading default"
       )

   ; is( $$o1{Bdefault}
       , 25
       , "Reading default (underlaying scalar check)"
       )

   ; $o1->Bvalid = 5
   ; is( $o1->Bvalid
       , 5
       , 'Writing an always valid property'
       )
   ; is( $$o1{Bvalid}
       , 5
       , 'Writing an always valid property (underlaying scalar check)'
       )

   ; $o1->writeBprotA(5)
   ; is( $o1->BprotA
       , 5
       , "Writing protected property from class"
       )
   ; is( $$o1{BprotA}
       , 5
       , "Writing protected property from class (underlaying scalar check)"
       )
       
   ; eval
      { $o1->BprotA = 10
      }
   ; ok( $@
       , 'Trying to write a protected property from outside'
       )

   ; $o1->writeBprotA(8)
   ; is( $o1->BprotA
       , 8
       , "Writing again protected property from class"
       )
   ; is( $$o1{BprotA}
       , 8
       , "Writing again protected property from class (underlaying scalar check)"
       )

   ; is( $o1->Bvalidat('aawwwbb')
       , 'aawwwbb'
       , 'Writing a valid value'
       )

   ; is( $$o1{Bvalidat}
       , 'aawwwbb'
       , 'Writing a valid value (underlaying scalar check)'
       )

   ; eval
      { $o1->Bvalidat = 10
      }
   ; ok( $@
       , 'Writing an invalid value '
       )
       
   ; is( $o1->Bvalidat('aawwwbb')
       , 'aawwwbb'
       , 'Writing again a valid value'
       )
       
  ; is( $$o1{Bvalidat}
       , 'aawwwbb'
       , 'Writing again a valid value (underlaying scalar check)'
       )

   ; is( $o1->Bvalidat_default('aawwwbb')
       , 'aawwwbb'
       , 'Writing a valid value in a property with default'
       )

   ; is( $$o1{Bvalidat_default}
       , 'aawwwbb'
       , 'Writing a valid value in a property with default (underlaying scalar check)'
       )

   ; ok( (not $o1->Barr_namedA)
       , 'Default undef value'
       )

   ; ok( (not $$o1{Barr_namedA})
       , 'Default undef value (underlaying scalar check)'
       )

   ; $o1->Bdefault = 56
   ; undef $o1->Bdefault
   ; is( $o1->Bdefault
       , 25
       , 'Reset to default'
       )

   ; is( $$o1{Bdefault}
       , 25
       , 'Reset to default (underlaying scalar check)'
       )
   ; $o1->Bmod_input = 'abc'
   ; is( $o1->Bmod_input
       , 'ABC'
       , 'Modifying input'
       )
       
   ; is( $$o1{Bmod_input}
       , 'ABC'
       , 'Modifying input (underlaying scalar check)'
       )
       
   ; is( $o1->Brt_default
       , 25
       , 'Passing a sub ref as the rt_default'
       )
   ; is( $$o1{Brt_default}
       , 25
       , 'Passing a sub ref as the rt_default (underlaying scalar check)'
       )
 
   ; eval
      { my $v = $o1->Brt_default_val
      }
   ; ok( $@
       , 'Passing an invalid sub ref as the rt_default'
       )

   ; is( $o1->Brt_default_val_prot
       , 5
       , "Bypass protection for rt_default"
       )

   ; is( $$o1{Brt_default_val_prot}
       , 5
       , "Bypass protection for rt_default (underlaying scalar check)"
       )
   }


; package BaseClass

; use Class::constr


; use Object::props ( qw | BpropA
                           BpropB
                         |
                    , { name      => 'BnamedA'
                      }
                    , { name      => [ qw| Barr_namedA
                                           Barr_namedB
                                         |
                                     ]
                      }
                    , { name       => 'Bdefault'
                      , default    => 25
                      }
                    , { name       => 'Brt_default'
                      , default => sub{ 25 }
                      }
                    , { name       => 'Brt_default_val_prot'
                      , default => sub{ 5 }
                      , validation => sub { $_ < 25 }
                      , protected => 1
                      }
                    , { name       => 'BprotA'
                      , protected  => 1
                      }
                    , { name       => 'Bvalid'
                      , validation => sub { 1 }
                      }
                    , { name       => 'Binvalid'
                      , validation => sub { 0 }
                      }
                    , { name       => 'Bvalidat'
                      , validation => sub { /www/ }
                      }
                    , { name       => 'Bvalidat_default'
                      , validation => sub { /www/ }
                      , default    => 'wwwddd'
                      }
                    , { name       => 'Bmod_input'
                      , validation => sub { $_ = uc }
                      }
                    )
; sub writeBprotA
   { my ($s, $v) = @_
   ; $s->BprotA = $v
   }
                                 
; package SubClass
; use base 'BaseClass'





