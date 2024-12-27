use v5.20;
use warnings;

use Test2::V0;

use Sys::GetRandom::FFI qw( getrandom GRND_NONBLOCK GRND_RANDOM );

ok my $bytes = getrandom(16), "got bytes";
is length($bytes), 16, "expected length";

note( join(" ", unpack("N*", $bytes) ) );

done_testing;
