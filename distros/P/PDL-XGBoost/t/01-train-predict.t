use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use PDL;
use PDL::XGBoost qw(dmatrix train load_model);

my $X = float([
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 6],
    [6, 7],
]);
my $y = float([3, 5, 7, 9, 11, 13]);

my $dm = dmatrix($X, $y);
isa_ok($dm, 'PDL::XGBoost::DMatrix');
is($dm->num_row(), 6, 'DMatrix has 6 rows');
is($dm->num_col(), 2, 'DMatrix has 2 cols');

my $booster = train(
    $dm, undef,
    num_boost_round => 60,
    params          => {
        objective => 'reg:squarederror',
        max_depth => 3,
        eta       => 0.3,
    },
);
isa_ok($booster, 'PDL::XGBoost::Booster');

my $preds = $booster->predict($dm);
my $max_err = abs($preds - $y)->max();
ok($max_err < 0.1, 'training predictions match labels (max_err=' . $max_err . ')');

my ($fh, $model_path) = tempfile('pdl_xgb_XXXXXX', SUFFIX => '.ubj', UNLINK => 1);
close $fh;

$booster->save_model($model_path);
ok(-s $model_path, 'saved XGBoost UBJ model file');

my $reloaded = load_model($model_path);
my $preds2   = $reloaded->predict($dm);
my $reload_diff = abs($preds - $preds2)->max();
ok($reload_diff < 1e-5, 'reloaded model predictions match exactly');

done_testing();
