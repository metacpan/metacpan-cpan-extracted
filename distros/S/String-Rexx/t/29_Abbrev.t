use Test::More ;
use Test::Exception;
use String::Rexx qw( Abbrev );


BEGIN { plan tests =>  8 };



### Basic Usage
is    Abbrev( 'apple', 'app'       )      =>    1    ;
is    Abbrev( 'apple', 'app' , 2   )      =>    1    ;
is    Abbrev( 'apple', 'pp'  , 2   )      =>    1    ;
is    Abbrev( 'apple', 'pp'  , 3   )      =>    0    ;
is    Abbrev( 'apple', 'pp'  , 1   )      =>    1    ;
is    Abbrev( 'apple', 'Dapp'      )      =>    0    ;


# Extra

SKIP: {
        eval {  require Test::Exception ; Test::Exception::->import } ;
        skip 'Test::Exception not available',  2   if $@ ;

        dies_ok  (  sub { Abbrev(apple => 'app' , -1    )}    );
        lives_ok (   sub { Abbrev(apple => 'app' , 0    )}    );
}

