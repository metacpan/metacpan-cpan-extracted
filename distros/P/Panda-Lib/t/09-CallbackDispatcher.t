use 5.012;
use warnings;
use Panda::Lib;
use Test::More;
use Test::Deep;

my $d = new Panda::Lib::CallbackDispatcher();
my %called;
my $cb1 = sub { $called{1} = [@_] };
$d->add($cb1);

$d->call();
cmp_deeply(\%called, {1 => []}, "simple call ok");
%called = ();

$d->call(10);
cmp_deeply(\%called, {1 => [10]}, "simple call with argument ok");
%called = ();

$d->call(1, 2);
cmp_deeply(\%called, {1 => [1, 2]}, "simple call with arguments ok");
%called = ();

my $cb2 = sub { $called{2} = [@_] };
$d->add($cb2);

$d->call(1,2);
cmp_deeply(\%called, {1 => [1, 2], 2 => [1,2]}, "simple multiple call with arguments ok");
%called = ();

$d->remove($cb1);
$d->call([1], {1 => 2});
cmp_deeply(\%called, {2 => [[1],{1 => 2}]}, "simple multiple call with arguments ok");
%called = ();

my $cb3 = sub { $called{3} = [@_] };
$d->add_ext($cb3);
$d->call(3, 3);
cmp_deeply(\%called, {2 => [3, 3], 3 => [ignore(), 3, 3]}, "simple multiple call with arguments ok");
%called = ();

$d->remove($cb3);
$d->call(3, 3);
cmp_deeply(\%called, {2 => [3, 3]}, "simple multiple call with arguments ok");
%called = ();

done_testing();
