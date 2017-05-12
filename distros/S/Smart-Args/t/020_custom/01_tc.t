use strict;
use warnings;
use Test::Requires { 'MouseX::Types' => 0.05 };
use Smart::Args;
use Test::More;
use t::Util;
use MouseX::Types::Mouse qw(Int);

lives_ok { foo(foo => 3) }; # yutori is good
is foo(foo => 3), 6;
throws_ok { foo(foo => 3.14) } qr/Validation failed for 'Int' with value 3.14/;
done_testing;
exit;

sub foo {
    args my $foo => Int;
    $foo*2;
}
