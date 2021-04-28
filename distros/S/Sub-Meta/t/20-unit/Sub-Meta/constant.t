use Test2::V0;

use Sub::Meta;

use constant PI => 4 * atan2(1, 1);
sub one() { 1 } ## no critic (RequireFinalReturn)
sub two() { return 2 }

ok(Sub::Meta->new(sub => \&PI)->is_constant);
ok(Sub::Meta->new(sub => \&one)->is_constant);
ok(!Sub::Meta->new(sub => \&two)->is_constant);

done_testing;
