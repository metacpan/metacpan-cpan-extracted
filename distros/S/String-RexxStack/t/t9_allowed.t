use Test::More ;
use String::TieStack  ;

BEGIN { plan tests => 19 }

my $t = tie my @arr , 'String::TieStack';
my $ret;

@arr = ();
$t->max_entries(undef) ;
$t->max_KBytes(undef) ;
push  @arr , qw( zero ) ;
ok    $t->_allowed_p( qw(three) )               ,  'entries=undef   KBytes=undef' ;

@arr = ();
$t->max_KBytes(0.005) ;
$t->max_entries(undef) ;
push  @arr , qw( zero ) ;
is   $t->total_bytes                    =>  4   ,  'entries=undef   KBytes=0.005' ;
ok   $t->_allowed_p( 'a'  )  ;
is   $t->_allowed_p( 'aa' )             =>  0   ;


@arr = ();
$t->max_entries(3) ;
$t->max_KBytes(undef) ;
push  @arr , qw( zero one ) ;
ok   $t->_allowed_p( qw(three) )                ,  'entries=3   KBytes=undef' ;
is   $t->_allowed_p( qw(three four) )   =>  0   ;


@arr = ();
$t->max_entries(0) ;
$t->max_KBytes(0) ;
push  @arr , qw( zero one ) ;
ok   $t->_allowed_p( qw(three) )                ,  'entries=0   KBytes=0' ;
ok   $t->_allowed_p( qw(three four) )  ;


@arr = ();
$t->max_entries(0) ;
$t->max_KBytes(0.005) ;
push  @arr , 'zero' ;
ok   $t->_allowed_p( 'a'  )                      ,  'entries=0   KBytes=0.005' ;
is   $t->_allowed_p( 'bb' )   =>  0    ;
is   $t->_allowed_p( qw(three four) )   =>  0    ;



@arr = ();
$t->max_entries(3) ;
$t->max_KBytes(0) ;
push  @arr , qw( zero one ) ;
ok   $t->_allowed_p( qw(three) )                  ,  'entries=3   KBytes=0' ;
is   $t->_allowed_p( qw(three four) )   =>  0     ;


@arr = ();
$t->max_entries(3) ;
$t->max_KBytes(0.005) ;
push  @arr , qw( a b )  ;
ok   $t->_allowed_p( 'c' )                         ,  'entries=3   KBytes=0.005' ;
ok   $t->_allowed_p( 'cc' )    ;
ok   $t->_allowed_p( 'ccc' )   ;
is   $t->_allowed_p( qw( c  d) )         =>  0     ;
is   $t->_allowed_p( 'three' )           =>  0     ;
is   $t->_allowed_p( qw(three four) )    =>  0     ;



#$t->pdumpq ;

