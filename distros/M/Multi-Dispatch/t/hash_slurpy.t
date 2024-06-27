use v5.22;
use warnings;

use Test::More;

use Multi::Dispatch;
plan tests => 4;

multi slurp  (%slurpy) { \%slurpy }

is_deeply slurp(),           {}           => "Empty argument list";
is_deeply slurp(a=>1, b=>2), {a=>1, b=>2} => "Even argument list";

my $failed = 1;
eval { slurp(1..3); $failed = 0; },
ok $failed                                => "Odd argument list fails";
like $@, qr/\AOdd number of arguments passed to slurpy %slurpy parameter of multi slurp()/ 
                                          => "...with correct error message";

done_testing();


