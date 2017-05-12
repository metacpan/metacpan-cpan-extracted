use strict;
use warnings;

use Test::More tests => 3;

use Params::Named;

## Thanks to Robin Houston for this and the new version of PadWalker -
## http://use.perl.org/comments.pl?sid=28953&cid=43856

sub ick {
    MAPARGS \my($foo, $bar);
    {my $foo}
    return $foo;
}

my $val = eval { ick(foo => 42, bar => 1) };

ok !$@, "Didn't break on with multiple decls of \$foo";
ok defined $val, 'Something was returned';
cmp_ok $val, '==', 42, "The returned value was the answer";
