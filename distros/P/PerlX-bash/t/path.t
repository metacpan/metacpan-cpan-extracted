use Test::Most 0.25;

use PerlX::bash ':all';

use Cwd;
use Path::Tiny qw< tempdir >;


my $cwd = cwd;

my $dir = tempdir;
chdir $dir or die("can't change to test dir");

is pwd, $dir, "pwd returns current directory";


chdir $cwd;

done_testing;
