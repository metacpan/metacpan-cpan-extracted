use strict;
use warnings;
use Smart::Args;
use Test::More;
use t::Util;

throws_ok { foo(bar => 3.14) } qr/@{[ quotemeta(__FILE__) ]}/;
note $@;
done_testing;
exit;

sub foo {
    args my $bar => 'Num';
    baz(boss => $bar);
}

sub baz {
    args my $boss => 'Int';
    return $boss * 3
}

