#!/usr/bin/perl -w

use Test::More;
use Test::Deep;

use qbit;

use FindBin qw($Bin);

use lib "$Bin/../lib";
use lib "$Bin/lib";

use TestApplication;

my $app = TestApplication->new();

$app->pre_run();

my $model_fields = $app->test_model->get_model_fields();

my $removed_model_fields = $app->test_model->remove_model_fields();

cmp_deeply($removed_model_fields, $model_fields, 'fields');

cmp_deeply(
    [sort keys(%$app)],
    ['__CURRENT_USER_RIGHTS__', '__OPTIONS__', '__ORIG_OPTIONS__', '__TIMELOG_CLASS__', 'test_model', 'timelog'],
    'private options'
);

$app->post_run();

done_testing();
