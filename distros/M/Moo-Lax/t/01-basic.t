use Test::More;

use Moo::Lax;

local $SIG{__WARN__} = sub {};
my $ret = eval { my $f; my $g = 5 . $f; 1 };
ok($ret, "we had a non fatal warning");

done_testing;

