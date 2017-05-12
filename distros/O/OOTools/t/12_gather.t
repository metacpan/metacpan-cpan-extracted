#!perl -w
; package My::a
; sub test { 'a' }
; our $test = 'A'
; our @test = ('A')
; our %default = ( a=>1, b=>2 )

; package My::b
; our @ISA = 'My::a'
; sub test { 'b' }
; our $test = 'B'
; our @test = ('B')
; our %default = (a=>10, c=>3)
; sub My::b::_::test { '_b'}

; package My::c
; sub test { 'c' }
; our $test = 'C'
; our @test = ('C')
; sub My::c::_::test { '_c'}


; package My::d
; sub test { 'd' }
; our $test = 'D'
; our @test = ('D')
; our @ISA = qw| My::a  My::b  My::c |
; our %default = ( d=>5 )
; sub My::d::_::test

; package main
; use strict
; use warnings
; use Test::More tests => 5
#; use Data::Dumper
; use Class::Util qw|gather|

   
; my @res = gather { $_->() } '&test', [ qw| My::a  My::b  My::c My::d | ]
; is join ('', @res), 'abcd', 'CODE'

; @res = gather { @$_ } '@test', 'My::d'
; is join ('', @res), 'CBAD', 'ARRAY'

; @res = gather { $$_ } '$test', (bless {}, 'My::d')
; is join ('', @res), 'CBAD', 'SCALAR'

; my %defaults = gather { %$_ } '%default', [ qw| My::a  My::b  My::c My::d | ]
; is_deeply \%defaults, { 'a' => 10
                        , 'b' => 2
                        , 'c' => 3
                        , 'd' => 5
                        }, 'HASH'



; eval {gather { %$_ } 'default'}
; ok $@, 'Symbol check'


__END__

     a
     |\
     | b c
      \|/
       d
