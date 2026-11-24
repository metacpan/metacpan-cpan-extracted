use strict;
use warnings;
use Test::More;

use_ok('PDL::XGBoost', qw(xgboost_version dmatrix train load_model));

my $ver = xgboost_version();
like($ver, qr/^\d+\.\d+\.\d+$/, 'xgboost_version returns semver (' . $ver . ')');

done_testing();
