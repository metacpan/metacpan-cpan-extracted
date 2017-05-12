#!perl -w

; use strict
; use Test::More tests => 20
; use strict
#; use Data::Dumper

; my $base  = BaseClass->new
; my $sub   = SubClass->new
; my $other = Other->new

; is_deeply( scalar $base->group1
           , { one => 2
             , two => 2
             }
           )

; is_deeply( scalar BaseClass->group1
           , { one => 2
             , two => 2
             }
           )

; is_deeply( \%BaseClass::group1
           , { one => 2
             , two => 2
             }
           )

; is_deeply( scalar $sub->group1
           , { one   => 4
             , two   => 2
             , three => 4,
             }
           )

; is_deeply( scalar SubClass->group1
           , { one   => 4
             , two   => 2
             , three => 4,
             }
           )

; is_deeply( \%SubClass::group1
           , { one   => 4
             , two   => 2
             , three => 4,
             }
           )

; $base->group1( one => 1
               , two => 2
               )

; is_deeply( scalar $base->group1
           , { one   => 1
             , two   => 2
             }
           )

; is_deeply( scalar BaseClass->group1
           , { one   => 1
             , two   => 2
             }
           )

; is_deeply( \%BaseClass::group1
           , { one   => 1
             , two   => 2
             }
           )

; $sub->one   = 1
; $sub->two   = 2
; SubClass->three = 3
; is_deeply( scalar $sub->group1
           , { one   => 1
             , two   => 2
             , three => 3,
             }
           )

; is_deeply( scalar SubClass->group1
           , { one   => 1
             , two   => 2
             , three => 3,
             }
           )

; is_deeply( \%SubClass::group1
           , { one   => 1
             , two   => 2
             , three => 3,
             }
           )


; is_deeply( scalar $other->group1
           , { one   => 4
             , two   => 2
             , three => 4
             , four  => undef
             }
           )

; is_deeply( scalar Other->group1
           , { one   => 4
             , two   => 2
             , three => 4
             , four  => undef
             }
           )

; is_deeply( \%Other::group1
           , { one   => 4
             , two   => 2
             , three => 4
             , four  => undef
             }
           )

# double check init and defaults
; is_deeply( scalar $other->group1
           , { one   => 4
             , two   => 2
             , three => 4
             , four  => undef
             }
           )

; is_deeply( \%Other::group1
           , { one   => 4
             , two   => 2
             , three => 4
             , four  => undef
             }
           )

; $other->one = 1
; Other->three = 3

; is_deeply( scalar $other->group1
           , { one   => 1
             , two   => 2
             , three => 3
             , four  => undef
             }
           )


; is_deeply( scalar Other->group1
           , { one   => 1
             , two   => 2
             , three => 3
             , four  => undef
             }
           )


; is_deeply( \%Other::group1
           , { one   => 1
             , two   => 2
             , three => 3
             , four  => undef
             }
           )


   
; package BaseClass

; use Class::constr

; our @props
; BEGIN
   { @props = { name => [ "one"
                        , "two"
                        ]
              , default => 2
              }
              
   }
               
; use Class::groups{ name => 'group1'
                   , props => \@props
                   }
                   

                                 
; package SubClass
; use base 'BaseClass'

; use Class::groups {  name => 'group1'
                    ,  props => [ { name    => [ "one"
                                               , "three"
                                               ]
                                  , default => 4
                                  }
                                ]
                    }


; package Other
; use base 'SubClass'

; use Class::groups { name => 'group1'
                    , props => [ 'four' ]
                    }




