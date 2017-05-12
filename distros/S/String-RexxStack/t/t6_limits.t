use String::TieStack ;


use Test::More ;

BEGIN { plan tests => 40 }

my $ret ;
my $t = tie my @arr , 'String::TieStack';

is_deeply [$t->limits( 19, 20)], [19, 20]  , ' limits() ' ;
is    $t->max_entries()   =>  19 ;
is    $t->max_KBytes()    =>  20 ;
is_deeply [$t->limits(  0, 20)], [ 0, 20];
is    $t->max_entries()   =>   0 ;
is    $t->max_KBytes()    =>  20 ;
is_deeply [$t->limits( 19,  0)], [19,  0];
is    $t->max_entries()   =>  19 ;
is    $t->max_KBytes()    =>   0 ;
is_deeply [$t->limits(  0,  0)], [ 0,  0];
is    $t->max_entries()   =>   0 ;
is    $t->max_KBytes()    =>   0 ;
is_deeply [$t->limits(  undef,  undef)], [ undef,  undef];
is    $t->max_entries()   =>   undef ;
is    $t->max_KBytes()    =>   undef ;
is_deeply [$t->limits(  1,  undef)], [ 1,  undef];
is    $t->max_entries()   =>       1 ;
is    $t->max_KBytes()    =>   undef ;
is_deeply [$t->limits(  undef,  1)], [ undef,  1];
is    $t->max_entries()   =>   undef ;
is    $t->max_KBytes()    =>       1 ;



$t->max_entries(undef);
$t->max_KBytes(undef);
is_deeply  [$t->limits]        =>  [ 0, 0 ] ;

is  $t->max_entries()          => undef, 'default max_entries';
push @arr , qw( one two three four )   ;
is  @arr                       =>  4   ;

@arr = ();
is  $t->max_entries(0)         =>  0   ,   'max_entries=0';
push @arr , qw( one two three four );
is  @arr                       =>  4   ;

@arr = ();
is  $t->max_entries(2)         =>  2   ,   'max_entries=2';
push @arr , qw( one two three four )   ;
is  @arr                       =>  0   ;

@arr = ();
is  $t->max_entries(0)         =>  0   ,   'max_entries=0,  bytes=0';
is  $t->max_KBytes(0)          =>  0   ;
push @arr , qw( one two three four )   ;
is  @arr                       =>  4   ;

@arr = ();
is  $t->max_entries(0)         =>  0   ,   'max_entries=0,  bytes=1K';
is  $t->max_KBytes(1)          =>  1   ;
push @arr , qw( one two three four )   ;
is  @arr                       =>  4   ;

@arr = ();
is  $t->max_entries(2)         =>  2   ,  'max_entries=2,  bytes=0';
is  $t->max_KBytes(0)          =>  0   ;
push @arr , qw( one two three four );
is  @arr                       =>  0   ;

@arr = ();
is  $t->max_entries(2)         =>  2   ,  'max_entries=2,  bytes=1K';
is  $t->max_KBytes(1)          =>  1   ;
push @arr , qw( one two three four )   ;
is  @arr                       =>  0   ;

