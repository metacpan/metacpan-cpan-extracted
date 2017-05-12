use Pg::Loader::Misc;
use Test::More qw( no_plan );
use Test::Exception;

*_copy_param = \&Pg::Loader::Misc::_copy_param ;

my $ans = [qw( a b c d)];

is _copy_param( ' * ') , undef;

$a   = [qw( a:1 b d:4 c:3 )];
is_deeply _copy_param( $a) , $ans;

$a   = [qw( c:3 d:4 a:1 b )];
is_deeply _copy_param( $a) , $ans;

$a   = [qw( a b c d:4  )];
is_deeply _copy_param( $a) , $ans;

$a   = [qw( b:2 a:1 c:3 d )];
is_deeply _copy_param( $a) , $ans;
$a   = [ 'b:2 ', 'a :1',' c: 3', ' d' ];
is_deeply _copy_param( $a) , $ans;

$a   = [ ' b:2', 'a :  1',' c: 3', 'd  ' ];
is_deeply _copy_param( $a) , $ans;


$a   = ' a:1' ;
is_deeply _copy_param( $a) , ['a'];

exit;
$a = [ 'a:2'];
dies_ok { _copy_param($a) };

$a = [ 'a','b:3'];
dies_ok { _copy_param($a) };

