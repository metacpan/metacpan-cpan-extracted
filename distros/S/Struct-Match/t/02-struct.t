use Test::More;
use Struct::Match qw/match/;

$m = match [{'one' => 'two', three => 'four'}, 'five'], [{'one' => 'two', 'three' =>'four'}], 1;
is($m, 0);

$m = match [{'one' => 'two', three => 'five'}], [{'one' => {'one' => 'two'}, 'three' =>'four'}];
is($m, 0);

$m = match [{'one' => {'one'=>'two'}, three => 'four'}], [{'one' => 'two', 'three' =>'four'}];
is($m, 0);

$m = match [{'one' => {'one'=>'two'}, {three => 'four'}}], [{'one' => 'two', 'three' =>'four'}];
is($m, 0);

$m = match [{'one' => ['one','two'], three => 'four'}], [{'one' => 'two', 'three' =>'four'}];
is($m, 0);

$m = match [{'one' => ['one','two'], three => 'four'}], [{'one' => ['one','two', { three => 'four' }, {five => 'six'}], 'three' =>'four'}];
is($m, 0);

$m = match [{'one' => 'two', three => ['four']}], [{'one' => 'two', 'four' => ['four']}];
is($m, 0);

my $bt = sub { print 'Testing' };
$m = match $bt, {};
is($m, 0);

done_testing();
