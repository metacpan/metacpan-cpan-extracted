use strict;
use warnings;
use Test::More;
use PDL;
use PDL::ML::Preprocess qw(train_test_split standard_scale minmax_scale l2_normalize one_hot_encode);

my $X = sequence(double, 3, 10);
my $y = sequence(long, 10);

my ($X_tr, $X_te, $y_tr, $y_te) = train_test_split($X, $y, test_size => 0.2, seed => 42);
is($X_tr->dim(1), 8, 'train has 8 samples');
is($X_te->dim(1), 2, 'test has 2 samples');
is($y_tr->nelem, 8, 'y_train has 8 labels');
is($y_te->nelem, 2, 'y_test has 2 labels');

my ($X_std, $mean, $std) = standard_scale($X);
ok(all(abs($X_std->transpose->average) < 1e-6), 'standard_scale mean ~ 0');

my ($X_mm) = minmax_scale($X);
ok(all($X_mm >= -1e-9) && all($X_mm <= 1 + 1e-9), 'minmax_scale in [0, 1]');

my $V = double([[3, 4], [0, 5]]);
my $Vn = l2_normalize($V);
ok(all(approx(sqrt(($Vn * $Vn)->sumover), pdl([1, 1]))), 'l2_normalize unit norms');

my $oh = one_hot_encode(long([0, 2, 1]), 3);
is_deeply([ $oh->dims ], [3, 3], 'one_hot dims');
is($oh->at(0, 0), 1, 'one_hot class 0');
is($oh->at(2, 1), 1, 'one_hot class 2');
is($oh->at(1, 2), 1, 'one_hot class 1');

done_testing();
