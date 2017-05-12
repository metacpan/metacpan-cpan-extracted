use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use MooseX::Types::Moose qw(Int Num);
use MooseX::Types::Structured qw(Map);

my $type = Map[ Int, Num ];

ok($type->assert_valid({ 10 => 10.5 }), "simple Int -> Num mapping");

like( exception { $type->assert_valid({ 10.5 => 10.5 }) },
    qr{value .*10\.5.*}, "non-Int causes rejection on key");

like( exception { $type->assert_valid({ 10 => "ten and a half" }) },
    qr{value .*ten and a half.*}, "non-Num value causes rejection on value");

ok($type->assert_valid({ }), "empty hashref is a valid mapping of any sort");

done_testing;

