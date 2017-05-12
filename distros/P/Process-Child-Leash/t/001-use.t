use strict;
use warnings;
use Test::More;

eval "use Process::Child::Leash test => 1";

ok !$@, "no error $@";

done_testing;
