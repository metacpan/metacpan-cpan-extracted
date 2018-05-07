use lib 't/lib';

use Test::More;

use qbit;

use TestApplication;

my $app = new_ok(TestApplication => []);

$app->pre_run();

is($app->test_model->method(), 12345, 'Checking model\'s mehod call');

# Check tmp rights without cur_user
$app->cur_user({});
my $tmp = $app->add_tmp_rights('tmp_right_for_wo_cur_user_test');
is($app->check_rights('tmp_right_for_wo_cur_user_test'), TRUE, 'Checking tmp rights without cur_user');
undef($tmp);

$app->post_run();

done_testing();
