use Test::More 'no_plan';
use Telephone::Mnemonic::US::Math qw/ combinethem / ;

*combine_one = *Telephone::Mnemonic::US::Math::combine_one  ;
*combinethem = *Telephone::Mnemonic::US::Math::combinethem  ;
*sets2candidates = *Telephone::Mnemonic::US::Math::sets2candidates  ;


my $two    =  [ [qw/d e f/], [qw/d e f/] ] ;
my $ans2   =  [ qw/ dd de df ed ee ef fd fe ff / ];
my $three  =  [ [qw/a b c/], [qw/d e f/], [qw/d e f/] ] ;

is_deeply  combine_one( 'i', [qw/a b/])  , [qw/ ia ib/];
is_deeply  combine_one( 'i', [])  , [qw/ /];

is_deeply  combinethem( ['i'], [qw/a b/])  , [qw/ ia ib/];
is_deeply  combinethem( [qw/i j/], [qw/a b/])  , [qw/ ia ib ja jb/];
is_deeply  combinethem( [qw/ i z/], [])  , [qw/i z /];

is scalar @{sets2candidates( $three )} , 27;
is_deeply sets2candidates( $two ), $ans2;

exit;
my $boat = [ [ 'm', 'n', 'o' ], [ 'a', 'b', 'c' ], [ 't', 'u', 'v' ] ];
say Dumper [ @{sets2candidates( $boat )} ];
