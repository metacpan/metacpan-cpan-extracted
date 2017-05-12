
use Test;
BEGIN { plan tests => 1 };
BEGIN { $ENV{MOD_PERL} = 1 }; # for precompile
use Stream::Reader 0.09;
ok(1);
