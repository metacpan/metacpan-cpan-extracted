use strict;
use warnings;
use Smart::Args;
use Test::More;
use t::Util;

lives_ok { foo(bar => 3) }; # yutori is good
is foo(bar => 3), 6;
throws_ok { foo(bar => 3.14) } qr/'bar': Validation failed for 'Int' with value 3.14/;
done_testing;
exit;

sub foo {
    args my $bar => 'Int';
    $bar*2;
}
