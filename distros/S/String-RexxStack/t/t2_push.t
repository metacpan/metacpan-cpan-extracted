use String::TieStack;

use Test::More ;

BEGIN { plan tests => 4 }

my $t = tie my @arr , 'String::TieStack' ;

push @arr , 'zero';
push @arr , 'one', 'two',  'three' ;
is  @arr   => 4;

unshift @arr , '-one';
is  @arr   => 5;
unshift @arr ,  '-four', '-three', '-two';
is  @arr   => 8;
pop @arr;
is  @arr   => 7;

#print Dumper $t;
