#!perl -w
; use strict
; use Test::More tests => 74

; common_test('BaseClass', 'BaseClass');
; common_test('BaseClass', 'SubClass');

; sub common_test
   { my ($class, $subclass) = @_
   ; no strict 'refs'
   ; my $o1 = $subclass->new
   ; isa_ok( $o1
           , $class
           , 'Object creation'
           )

   ; my $o2 = $subclass->new( BpropA => 25
                            , BpropB => 3
                            )
   ; is( $o2->BpropA * $o2->BpropB
       , 75
       , 'Passing new properties with new' )

   ; is( $subclass->BpropA * $subclass->BpropB
       , 75
       , 'Accessing properties with subclass' )

   ; is( $class->BpropA * $class->BpropB
       , 75
       , 'Accessing properties with class' )

       
   ; is( ${$class.'::BpropA'} * ${$class.'::BpropB'}
       , 75
       , 'Passing new properties with new (underlaying scalar check)'
       )

   ; is( $o1->BpropA * $o1->BpropB
       , 75
       , 'Other object same test' )
        
   ; is( ${$class.'::BpropA'} * ${$class.'::BpropB'}
       , 75
       , 'Other object same test (underlaying scalar check)' )
        
   ; eval
      { my $o3 = $subclass->new( unknown => 10 )
      }
   ; ok( $@
       , 'Passing an unknow property'
       )
    
   ; eval
      { my $o3 = $subclass->new( Bprot => 10 )
      }
   ; ok( $@
       , 'Passing a value to a protected property'
       )
    
   ; is( $subclass->Bdefault
       , 25
       , "Reading default"
       )

   ; is( $class->Bdefault
       , 25
       , "Reading default"
       )

   ; is( ${$class.'::Bdefault'}
       , 25
       , "Reading default (underlaying scalar check)"
       )

   ; $subclass->Bvalid = 5
   ; is( $subclass->Bvalid
       , 5
       , 'Writing an always valid property'
       )

   ; is( ${$class.'::Bvalid'}
       , 5
       , 'Writing an always valid property (underlaying scalar check)'
       )

   ; $subclass->writeBprotA(5)
   ; is( $subclass->BprotA
       , 5
       , "Writing protected property from class"    #####
       )
       
   ; is( ${$class.'::BprotA'}
       , 5
       , "Writing protected property from class (underlaying scalar check)"    #####
       )
       
   ; eval
      { $subclass->BprotA = 10
      }
   ; ok( $@
       , 'Trying to write a protected property from outside'
       )

   ; $subclass->writeBprotA(8)
   ; is( $subclass->BprotA
       , 8
       , "Writing again protected property from class"
       )
   ; is( ${$class.'::BprotA'}
       , 8
       , "Writing again protected property from class (underlaying scalar check)"
       )

   ; is( $subclass->Bvalidat('aawwwbb')
       , 'aawwwbb'
       , 'Writing a valid value'
       )
   ; is(  ${$class.'::Bvalidat'}
       , 'aawwwbb'
       , 'Writing a valid value (underlaying scalar check)'
       )

   ; eval
      { $subclass->Bvalidat = 10
      }
   ; ok( $@
       , 'Writing an invalid value'
       )
       
   ; is( $subclass->Bvalidat('aawwwbb')
       , 'aawwwbb'
       , 'Writing again a valid value'
       )
       
   ; is(  ${$class.'::Bvalidat'}
       , 'aawwwbb'
       , 'Writing again a valid value (underlaying scalar check)'
       )

   ; is( $subclass->Bvalidat_default('aawwwbb')
       , 'aawwwbb'
       , 'Writing a valid value in a property with default'
       )

   ; is(  ${$class.'::Bvalidat_default'}
       , 'aawwwbb'
       , 'Writing a valid value in a property with default (underlaying scalar check)'
       )

   ; ok( (not $subclass->Barr_namedA)
       , 'Default undef value'
       )

   ; ok( ( not ${$class.'::Barr_namedA'} )
       , 'Default undef value (underlaying scalar check)'
       )

   ; $subclass->Bdefault = 56
   ; undef $subclass->Bdefault
   ; is( $subclass->Bdefault
       , 25
       , 'Reset to default'
       )

   ; is( ${$class.'::Bdefault'}
       , 25
       , 'Reset to default (underlaying scalar check)'
       )

   ; $subclass->Bmod_input = 'abc'
   ; is( $subclass->Bmod_input
       , 'ABC'
       , 'Modifying input'
       )
   ; is( ${$class.'::Bmod_input'}
       , 'ABC'
       , 'Modifying input (underlaying scalar check)'
       )
       
   ; is( $subclass->Brt_default
       , 25
       , 'Passing a sub ref as the rt_default'
       )

   ; is( ${$class.'::Brt_default'}
       , 25
       , 'Passing a sub ref as the rt_default (underlaying scalar check)'
       )

   ; eval
      { $subclass->Brt_default_val
      }
   ; ok( $@
       , 'Passing an invalid sub ref as the rt_default'
       )

   ; is( $subclass->Brt_default_val_prot
       , 5
       , "Bypass protection for rt_default"
       )
   ; is( ${$class.'::Brt_default_val_prot'}
       , 5
       , "Bypass protection for rt_default (underlaying scalar check)"
       )
   }


; package BaseClass

; use Class::constr


; use Package::props ( qw | BpropA
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
                   , { name => 'Brt_default'
                     , default    => sub{ 25 }
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





