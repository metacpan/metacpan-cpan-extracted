use Test::More;

use Struct::Match qw/match/;

my $m = match [{'one' => 'two', three => 'four'}], [{'one' => 'two', 'three' =>'four'}];
is($m, 1);

my $m = match [{'one' => 'two', three => 'five'}], [{'one' => 'two', 'three' =>'four'}];
is($m, 0);

$m = match [{'one' => 'two', three => ['four']}], [{'one' => 'two', 'three' => ['four']}];
is($m, 1);

$m = match [{'one' => 'two', three => ['five']}], [{'one' => 'two', 'three' => ['four']}];
is($m, 0);

done_testing();
