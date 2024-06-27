use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 17;

use Multi::Dispatch;

multi foo  ($aref,     $href        )                { return [$aref, $href]       }
multi foo  ([$a1, @a], $href        )                { return [$a1, \@a, $href]    }
multi foo  ([$a1, @a], {a=>$h1, %h} )                { return [$a1, \@a, $h1, \%h] }
multi foo  ([$a1, @a], {a=>[$ha1, @h], %h} )         { return [$a1, \@a, $ha1, \@h, \%h] }
multi foo  ([$a1, @a], {a=>[$ha1, {hh=>$hh}], %h} )  { return [$a1, \@a, $ha1, $hh, \%h] }

is_deeply foo([], {}),                                   [[], {}]                      => 'D0';
is_deeply foo([1..3], {}),                               [1,[2,3],{}]                  => 'D1';
is_deeply foo([1..3], {a=>9,   b=>10, c=>11}),           [1,[2,3],9,{b=>10,c=>11}]     => 'D2';
is_deeply foo([1..3], {a=>[0], b=>10, c=>11}),           [1,[2,3],0,[],{b=>10,c=>11}]  => 'D3';
is_deeply foo([1..3], {a=>[0, 1], b=>10, c=>11}),        [1,[2,3],0,[1],{b=>10,c=>11}] => 'D3b';
is_deeply foo([1..3], {a=>[0, {hh=>99}], b=>10, c=>11}), [1,[2,3],0,99,{b=>10,c=>11}]  => 'D4';


multi bar ({=>$name, => $rank, serial=>$snum}) {
    is $name, 'N' => 'name';
    is $rank, 'R' => 'rank';
    is $snum, 'S' => 'serial';
}

bar {name=>'N', rank=>'R', serial=>'S'};

multi baz ( i=>$i, j=>$j, %etc ) { return join ', ', 'Sije', $i, $j, sort keys %etc; }
multi baz ( i=>$i, j=>$j,      ) { return join ', ', 'NSij', $i, $j; }
multi baz ( x=>$x, y=>$y       ) { return join ', ', 'NSxy', $x, $y; }
multi baz (               %etc ) { return join ', ', 'Se', sort values %etc; }

is baz(j=>'J', 'i'=>'I', 'et' => 1, 'cetera' => 2), 'Sije, I, J, cetera, et' => 'Sije';
is baz(j=>'J', 'i'=>'I'                          ), 'NSij, I, J'             => 'NSij';
is baz(x=>'X', 'y'=>'Y'                          ), 'NSxy, X, Y'             => 'NSxy';
is baz(x=>'X', 'y'=>'Y', z=>'Z'                  ), 'Se, X, Y, Z'            => 'Se';


multi qux ({x=>{y=>$y, %}, %}) { return $y }
multi qux ([[$y, @], @])       { return $y }

is qux({x=>{y=>'Y'}}),                   'Y' => 'Anon hash slurpies (no slurp)';
is qux({x=>{y=>'Y', z=>'Z'}, a=>'A'}),   'Y' => 'Anon hash slurpies (slurp)';
is qux([['Y']]),                         'Y' => 'Anon array slurpies (no slurp)';
is qux([['Y','Z'],'X']),                 'Y' => 'Anon array slurpies (slurp)';

done_testing();




