use strict     ;
use Test::Exception;
use Test::More ;
use String::Rexx qw(verify);
 


BEGIN { plan tests =>  53  };


### Basic Usage
is   verify( perl  =>   'lper' )                 =>   0   ,   'match'  ;
is   verify( peLrl =>   'lper' )                 =>   3   ;
is   verify( perlL =>   'lper' )                 =>   5   ; 
is   verify( _ab   =>   'ba_'  )                 =>   0   ; 
is   verify( _ab   =>   'ba_'  )                 =>   0   ; 
is   verify( aaa   =>   'a'    )                 =>   0   ; 
is   verify( aaa   =>   'a'    )                 =>   0   ; 
is   verify( apple =>   'aple' )                 =>   0   ; 

is   verify( perl  =>   'lper' , 'n'      )      =>   0   ;
is   verify( peLrl =>   'dsju' , 'm'      )      =>   0   ;
is   verify( perlL =>   'john' , 'N'      )      =>   1   ; 
is   verify( Lperl =>   'lper' , 'M' , 1  )      =>   2   ;
is   verify( Lperl =>   'lper' , 'M' , 2  )      =>   2   ; 
is   verify( LPerl =>   'lper' , 'M' , 2  )      =>   3   ; 
is   verify( LPerl =>   'lper' , 'M' , 3  )      =>   3   ; 
is   verify( LP    =>   'lper' , 'M' , 4  )      =>   0   ; 

is  verify( apple =>    le =>  N => 4 )          =>   0   ;
is  verify( apple =>   ple =>  N => 3 )          =>   0   ;
is  verify( apple =>   ple =>  N => 2 )          =>   0   ;
is  verify( apple =>   ple =>  N => 1 )          =>   1   ;
is  verify( apple =>  aple =>  N => 2 )          =>   0   ;
is  verify( apple =>  aple =>  N => 1 )          =>   0   ;

is  verify( apple =>   e   =>  M => 5 )          =>   5   ;
is  verify( apple =>   f   =>  M => 5 )          =>   0   ;
is  verify( apple =>   l   =>  M => 5 )          =>   0   ;
is  verify( apple =>   a   =>  M => 1 )          =>   1   ;
is  verify( apple =>   a   =>  M => 2 )          =>   0   ;
is  verify( apple =>   p   =>  M => 2 )          =>   2   ;
is  verify( apple =>   p   =>  M => 3 )          =>   3   ;
is  verify( apple =>   p   =>  M => 4 )          =>   0   ;
is  verify( apple =>   l   =>  M => 4 )          =>   4   ;
is  verify( apple =>   e   =>  M => 5 )          =>   5   ;
is  verify( apple =>   l   =>  M => 5 )          =>   0   ;

is  verify( apple =>   e   =>  N => 6  )         =>   0   ;
is  verify( -ab   =>  ab   =>          )         =>   1   ;
is  verify( ab_p  =>  abp  =>          )         =>   3   ;
is  verify( ab_p  =>  abp  =>          )         =>   3   ;
is  verify( app   =>  ap   =>          )         =>   0   ;
is  verify( apple =>  aple =>          )         =>   0   ;
is  verify( apple =>     e =>  N => 5  )         =>   0   ;
is  verify( apple =>     e =>  N => 4  )         =>   4   ;
is  verify( apple =>    le =>  N => 4  )         =>   0   ;
is  verify( apple =>   ple =>  N => 3  )         =>   0   ;
is  verify( apple =>   ple =>  N => 2  )         =>   0   ;
is  verify( apple =>   ple =>  N => 1  )         =>   1   ;
is  verify( apple =>  aple =>  N => 2  )         =>   0   ;
is  verify( apple =>  aple =>  N => 1  )         =>   0   ;
is  verify( apple =>     e =>  N => 9  )         =>   0   ;
 
## Extra
is   verify( perl  =>   'lper' , 'M' , 1  )      =>   1   ; 
is   verify( perl  =>   ''     , 'M' , 1  )      =>   0   ; 
is   verify( ''    =>   'lper' , 'M' , 1  )      =>   0   ; 
is  verify( 'a+n*29' =>  'an2+9*' =>    )        =>   0   ;

dies_ok { verify( apple =>   a =>  M => 0 ) } ;

