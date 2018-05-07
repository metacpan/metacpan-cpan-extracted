use lib 't/lib';

use Test::More;
use Test::Deep;

use qbit;

use TestApplication;

TestApplication->use_config('TestApplication.json');

TestApplication->use_config('TestApplicationRedefined.cfg');

my $app = new_ok(TestApplication => []);

$app->pre_run();

is($app->get_option('ApplicationPath'), 't/', 'check ApplicationPath');

cmp_deeply(
    $app->get_option('test_model'),
    {
        param  => '${ApplicationPath}param/',
        param2 => [1, '${ApplicationPath}2/', 3],
        param3 => {
            key  => 1,
            key2 => [1, 2, 3],
            key3 => {key => 1,},
        },
    },
    'config ok'
);

is($app->test_model->get_option('param'), 't/param/', 'get param from config');
cmp_deeply($app->test_model->get_option('param2'), [1, 't/2/', 3], 'get param2 from config');
cmp_deeply(
    $app->test_model->get_option('param3'),
    {
        'key3' => {'key' => 1},
        'key'  => 1,
        'key2' => [1, 2, 3]
    },
    'get param3 from config'
);

is($app->get_option('global_param'), 'GlobalParam', 'JSON config ok');

is($app->get_option('global_param2'), 'Redefined', 'Param redefined');

$app->post_run();

done_testing();
