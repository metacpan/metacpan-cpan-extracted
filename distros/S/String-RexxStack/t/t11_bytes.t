use Test::More ;
use String::TieStack;
BEGIN { plan tests => 6 }


my $t = tie my @arr , 'String::TieStack';

push @arr , 'apple';
is  $t->total_bytes      =>  5 ;
push @arr , 'a';
is  $t->total_bytes      =>  6 ;
pop @arr;
is  $t->total_bytes      =>  5 ;
pop @arr;
is  $t->total_bytes      =>  0 ;
pop @arr;
is  $t->total_bytes      =>  0 ;
push @arr , 'a';
is  $t->total_bytes      =>  1 ;
