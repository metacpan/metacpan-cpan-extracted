use strict;
use warnings;
use Test::Requires { 'Moose' => 1.21, 'MooseX::Types' => 0.25 };
use Smart::Args;
use Test::More;
use t::Util;
use MooseX::Types::Moose qw(Int);

lives_ok { foo(foo => 3) }; # yutori is good
is foo(foo => 3), 6;
throws_ok { foo(foo => 3.14) } qr/Validation failed for 'Int' with value 3.14/;
done_testing;
exit;

sub foo {
    args my $foo => Int;
    $foo*2;
}
