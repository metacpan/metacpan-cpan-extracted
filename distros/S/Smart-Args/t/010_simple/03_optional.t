use strict;
use warnings;
use Smart::Args;
use Test::More;
use t::Util;

is foo(p => 3, q => 2), 3;
is foo(q => 2), 2;
throws_ok {foo(p => 2)} qr/missing mandatory parameter named '\$q'/;

done_testing;
exit;

sub foo {
    args my $p => { isa => 'Int', optional => 1 },
         my $q => { isa => 'Int', };
    return $p ? $p : $q;
}
