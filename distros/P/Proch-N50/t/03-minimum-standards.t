use strict;
use warnings;
use Test::More;
eval "use Test::Kwalitee 1.27 qw(kwalitee_ok)";
plan skip_all => "Test::Kwalitee 1.27 required to test distribution Kwalitee" if $@;
kwalitee_ok();
done_testing;
