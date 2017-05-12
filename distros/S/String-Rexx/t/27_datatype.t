use strict     ;
use Test::More ;
use Test::Exception;
use String::Rexx qw( datatype );
 


BEGIN { plan tests =>  17  };


### Basic Usage
is   datatype( '3'   )          =>   'NUM'     ; 
is   datatype( '33'  )          =>   'NUM'     ; 
is   datatype( 'aa'  )          =>   'CHAR'    ; 
is   datatype( '33'  , 'N')     =>       1     ; 
is   datatype( '33'  , 'A')     =>       1     ; 
is   datatype( 'a'   , 'A')     =>       1     ; 
is   datatype( 'aa'  , 'A')     =>       1     ; 
is   datatype( 'aa'  , 'N')     =>       0     ; 


is   datatype( '0'   , 'N')     =>       1     ; 
is   datatype( '0.0' , 'N')     =>       1     ; 
is   datatype( '0.1' , 'N')     =>       1     ; 
is   datatype( '00'  , 'N')     =>       1     ; 
is   datatype( '0a'  , 'A')     =>       1     ; 
is   datatype( '0.a' , 'A')     =>       0     ; 

#### Extra
is   datatype( ''         )     =>   'CHAR'    ; 
dies_ok  { datatype( '33'  , 'xLT')  }         ;
dies_ok  {  datatype( '33'  ,''   )  }         ; 
