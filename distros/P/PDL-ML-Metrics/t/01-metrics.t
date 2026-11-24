use strict;
use warnings;
use Test::More;
use PDL;
use PDL::ML::Metrics qw(accuracy precision_recall_f1 confusion_matrix mse rmse mae r2_score cosine_similarity roc_auc);

my $yt = long([1, 0, 1, 1, 0]);
my $yp = long([1, 0, 0, 1, 1]);

ok(abs(accuracy($yt, $yp) - 0.6) < 1e-6, 'accuracy == 0.6');
my ($p, $r, $f1) = precision_recall_f1($yt, $yp);
ok(abs($p - 2/3) < 1e-6, 'precision == 2/3');
ok(abs($r - 2/3) < 1e-6, 'recall == 2/3');
ok(abs($f1 - 2/3) < 1e-6, 'f1 == 2/3');

my $cm = confusion_matrix($yt, $yp, 2);
is($cm->at(1, 1), 2, 'TP == 2');
is($cm->at(0, 0), 1, 'TN == 1');

my $a = double([1, 2, 3]);
my $b = double([1, 2, 5]);
ok(abs(mse($a, $b) - 4/3) < 1e-6, 'mse');
ok(abs(rmse($a, $b) - sqrt(4/3)) < 1e-6, 'rmse');
ok(abs(mae($a, $b) - 2/3) < 1e-6, 'mae');
ok(abs(r2_score($a, $a) - 1.0) < 1e-6, 'r2_score == 1');
ok(abs(cosine_similarity(double([1, 0]), double([1, 0])) - 1.0) < 1e-6, 'cosine == 1');
ok(abs(roc_auc(long([0, 0, 1, 1]), double([0.1, 0.2, 0.8, 0.9])) - 1.0) < 1e-6, 'perfect roc_auc == 1');

done_testing();
