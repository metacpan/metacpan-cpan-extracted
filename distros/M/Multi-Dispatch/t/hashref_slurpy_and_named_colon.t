use v5.22;
use warnings;

use Test::More;

use Multi::Dispatch 'verbose';

plan tests => 4;

multi named_and_slurpy  ({:$x, :$y, :$z = 'Z', %slurpy}) { [$x, $y, $z, \%slurpy] }

is_deeply named_and_slurpy({a=>'A',x=>'X',y=>'Y'}),  ['X','Y','Z',{a=>'A'}]  => "default z";
is_deeply named_and_slurpy({z=>'ZZ',a=>'A',x=>'X',y=>'Y'}),  ['X','Y','ZZ',{a=>'A'}]  => "explicit z";

ok !eval{ named_and_slurpy({a=>'A',x=>'X'}) } => "missing y";
ok index($@, q{Required key (->{'y'}) not found in hashref argument $ARG[0]}) =>  "...with right error message";


done_testing();





