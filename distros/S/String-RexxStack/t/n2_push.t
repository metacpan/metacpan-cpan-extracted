use Test::More ;
use String::RexxStack::Named ;
BEGIN { plan tests => 9 }

my $ret ;

$ret = Push 'john', 'a';
is $ret => 1;
$ret = Push 'john', qw( b c d ) ;
is $ret => 4;
clear 'john';

$ret = Push  'apple';
is $ret => 1;
$ret = Push  'SESSION', qw( orange peach ) ;
is $ret => 3;
clear ;

Push    'three';
Queue   'two';
Queue  'SESSION' , qw( one zero);
is      qelem() =>  4;
Pull ;
is      qelem() =>  3;
Pull 2;
is      qelem() =>  1;
Pull 1;
is      qelem() =>  0;
pull ;
is      qelem() =>  0;

#info ;
#dumpe;
