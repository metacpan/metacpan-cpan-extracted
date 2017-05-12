use Pg::Loader::Misc;
use Test::More qw( no_plan );
use Test::Exception;

*_check_copy = \&Pg::Loader::Misc::_check_copy_grammar ;
my $a;

$a =  ' * ';
lives_ok {_check_copy($a) };

$a =  ' a ';
lives_ok {_check_copy($a) };

$a   =  undef ;
lives_ok {_check_copy($a) };

$a   = [qw( c:3 d:4 a:1 b )];
lives_ok   {_check_copy( $a)};

$a   = [qw( a b c d:4  )];
lives_ok   {_check_copy( $a)};

$a   = [qw( b:2 a:1 c:3 d )];
lives_ok  {_check_copy( $a)};

$a   = [ 'b:2 ', 'a :1',' c: 3', ' d' ];
lives_ok {_check_copy( $a) };


$a   = [ ' b:2', 'a :  1',' c: 3', 'd  ' ];
lives_ok {_check_copy( $a) };

$a   = ' a:1' ;
lives_ok {_check_copy( $a) };


exit;
$a =  ' a:';
dies_ok {_check_copy($a) };

$a =  'a:1';
lives_ok {_check_copy($a) };

$a =  'a:2';
dies_ok {_check_copy($a) };

$a = [ 'a','b', 'c:3',undef];
dies_ok {_check_copy($a) };

$a   = [ 'a', undef ];
dies_ok {_check_copy($a) };

$a   = [ undef ];
dies_ok {_check_copy($a) };

