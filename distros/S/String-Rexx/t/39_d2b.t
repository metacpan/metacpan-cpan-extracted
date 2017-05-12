use Test::More;
use Test::Exception;
use String::Rexx qw( d2b );


BEGIN { plan tests =>  6  };

is  d2b(30)  =>   '00011110';
is  d2b(0)   =>   '00000000';
is  d2b(1)   =>   '00000001';

dies_ok   { d2b 'fa'  }     ;
dies_ok   { d2b -3    }     ;
lives_ok  { d2b  0    }     ;
