use Test::More ;
use String::TieStack   max_KBytes=>.01 ;
## maximum allowed is 10.24 bytes ( 0.01*1024=10.24,  so it is 10 bytes);
BEGIN { plan tests => 10 }

my $t = tie my @arr , 'String::TieStack';
is  $t->max_entries    =>   0 ;
is  $t->max_KBytes     =>, .01 ;  # 10 bytes

push @arr , 'one', 'two';
is  @arr     => 2;
push @arr    => 'four';
is  @arr     => 3 ,    'should fit' ;
push @arr    => 't';
is  @arr     => 3    , 'should not fit';

@arr =();
push @arr , 'one';
is  @arr     => 1;
push @arr , 'two', 'three', 'four', 'five';
is  @arr     => 1;

@arr =();
push @arr , 'two', 'three', 'four', 'five';
is  @arr     => 0;

$t->max_KBytes( .005) ;   # max at 5.12 bytes 
push @arr, 'zero';
is @arr      => 1         ,  'test with max= 5 bytes';
push @arr, 'on';
is @arr     =>  1 ;
