use lib 't/lib';

use Test::More;
use Test::Deep;

use qbit;

use TestApplication;

my $USER = {id => 1};

my $app = new_ok(TestApplication => []);

$app->pre_run();

cmp_deeply($app->{'__CURRENT_USER_RIGHTS__'}, {}, 'check __CURRENT_USER_RIGHTS__ after init');

is($app->check_rights('RIGHT1'), FALSE, 'check_rights when rights empty');

my $tmp_rights = $app->add_tmp_rights(qw(RIGHT1 RIGHT2));

cmp_deeply(
    $app->{'__CURRENT_USER_RIGHTS__'},
    {RIGHT1 => 1, RIGHT2 => 1},
    'check __CURRENT_USER_RIGHTS__ with tmp_rights'
);

is($app->check_rights(qw(RIGHT1 RIGHT2)), TRUE, 'check_rights with exists rights');

is($app->check_rights(qw(RIGHT3)), FALSE, 'check_rights with not exists right');

is($app->check_rights([qw(RIGHT1 RIGHT3)]), TRUE, 'check_rights with exists right (or)');

my $tmp_rights2 = $app->add_tmp_rights(qw(RIGHT2 RIGHT3 RIGHT3));

cmp_deeply(
    $app->{'__CURRENT_USER_RIGHTS__'},
    {RIGHT1 => 1, RIGHT2 => 2, RIGHT3 => 2},
    'check __CURRENT_USER_RIGHTS__ with tmp_rights and tmp_rights2'
);

is($app->check_rights(qw(RIGHT1 RIGHT3)), TRUE, 'check_rights with exists rights');

is($app->check_rights(qw(RIGHT4)), FALSE, 'check_rights with not exists right');

@TestApplication::Model::RBAC::RIGHTS = qw(RIGHT4 RIGHT5 RIGHT5);

$app->cur_user($USER);

cmp_deeply(
    $app->cur_user(),
    {id => $USER->{'id'}, roles => $app->rbac->get_cur_user_roles(), rights => \@TestApplication::Model::RBAC::RIGHTS},
    'check current user'
);

cmp_deeply(
    $app->{'__CURRENT_USER_RIGHTS__'},
    {RIGHT1 => 1, RIGHT2 => 2, RIGHT3 => 2, RIGHT4 => 1, RIGHT5 => 2},
    'check __CURRENT_USER_RIGHTS__ with user, tmp_rights and tmp_rights2'
);

is($app->check_rights(qw(RIGHT3 RIGHT5)), TRUE, 'check_rights with exists rights');

is($app->check_rights(qw(RIGHT6)), FALSE, 'check_rights with not exists right');

is($app->check_rights([qw(RIGHT3 RIGHT4)]), TRUE, 'check_rights with exists right (or)');

@TestApplication::Model::RBAC::RIGHTS = qw(RIGHT1 RIGHT4 RIGHT5 RIGHT5);

$app->refresh_rights();

cmp_deeply(
    $app->cur_user(),
    {id => $USER->{'id'}, roles => $app->rbac->get_cur_user_roles(), rights => \@TestApplication::Model::RBAC::RIGHTS},
    'check current user'
);

cmp_deeply(
    $app->{'__CURRENT_USER_RIGHTS__'},
    {RIGHT1 => 2, RIGHT2 => 2, RIGHT3 => 2, RIGHT4 => 1, RIGHT5 => 2},
    'check __CURRENT_USER_RIGHTS__ with user, tmp_rights and tmp_rights2'
);

undef($tmp_rights2);

cmp_deeply(
    $app->{'__CURRENT_USER_RIGHTS__'},
    {RIGHT1 => 2, RIGHT2 => 1, RIGHT4 => 1, RIGHT5 => 2},
    'check __CURRENT_USER_RIGHTS__ with user and tmp_rights'
);

is($app->check_rights(qw(RIGHT2 RIGHT5)), TRUE, 'check_rights with exists rights');

is($app->check_rights(qw(RIGHT3)), FALSE, 'check_rights with not exists right');

$app->cur_user({});

cmp_deeply(
    $app->{'__CURRENT_USER_RIGHTS__'},
    {RIGHT1 => 1, RIGHT2 => 1,},
    'check __CURRENT_USER_RIGHTS__ with tmp_rights'
);

is($app->check_rights(qw(RIGHT1 RIGHT2)), TRUE, 'check_rights with exists rights');

is($app->check_rights(qw(RIGHT4)), FALSE, 'check_rights with not exists right');

undef($tmp_rights);

cmp_deeply($app->{'__CURRENT_USER_RIGHTS__'}, {}, 'check __CURRENT_USER_RIGHTS__');

is($app->check_rights(qw(RIGHT1)), FALSE, 'check_rights with not exists right');

$app->post_run();

done_testing();
