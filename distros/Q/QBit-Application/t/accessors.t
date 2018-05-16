use lib 't/lib';

use Test::More;
use Test::Deep;

use qbit;

package NewTestApplication;

use base qw(TestApplication);

use QBit::Application::Model::RBAC accessor => 'qbit_rbac';

package main;

use TestApplication;

my $accessors = {
    'rbac' => {
        'accessor' => 'rbac',
        'app_pkg'  => 'TestApplication',
        'package'  => 'TestApplication::Model::RBAC',
    },

    'test_model' => {
        'accessor' => 'test_model',
        'app_pkg'  => 'TestApplication',
        'package'  => 'TestApplication::Model::TestModel',
    }
};

my $models = TestApplication->get_models();

cmp_deeply($models, $accessors, 'accessors after "use"');

TestApplication->set_accessors(test_model_too => {package => 'TestApplication::Model::TestModel'});

$accessors = {
    %$accessors,
    'test_model_too' => {
        'accessor' => 'test_model_too',
        'app_pkg'  => 'TestApplication',
        'package'  => 'TestApplication::Model::TestModel',
    },
};

$models = TestApplication->get_models();

cmp_deeply($models, $accessors, 'accessors after "set_accessors"');

foreach my $acc (keys(%$models)) {
    is(TestApplication->can($acc), undef, qq{not exists method "$acc"});
}

my $app = TestApplication->new();    # step: init_accessors

map {$_->{'init'} = TRUE} values(%$accessors);

cmp_deeply($models, $accessors, 'accessors after init');

foreach my $acc (keys(%$models)) {
    is(!!$app->can($acc), 1, qq{exists method "$acc"});

    is(ref($app->$acc), $accessors->{$acc}{'package'}, qq{Class name correctly for accessor "$acc"});
}

$app->set_accessors(rbac_too => {package => 'TestApplication::Model::RBAC'});

$accessors = {
    %$accessors,
    'rbac_too' => {
        'accessor' => 'rbac_too',
        'app_pkg'  => 'TestApplication',
        'package'  => 'TestApplication::Model::RBAC',
    },
};

$models = $app->get_models();

cmp_deeply($models, $accessors, 'set accessor "rbac_too"');

is($app->can('rbac_too'), undef, 'not exists method "rbac_too"');

$app->init_accessors();

$accessors->{'rbac_too'}{'init'} = TRUE;

is(!!$app->can('rbac_too'), 1, 'exists method "rbac_too"');

is(ref($app->rbac_too), 'TestApplication::Model::RBAC', 'Class name for "rbac_too" correctly');

# Second app
my $app2 = TestApplication->new();

$models = $app2->get_models();

cmp_deeply($models, $accessors, 'accessors second app');

foreach my $acc (keys(%$models)) {
    is(!!$app2->can($acc), 1, qq{exists method "$acc" for second app});

    is(ref($app2->$acc), $accessors->{$acc}{'package'}, qq{Class name correctly for method "$acc" from second app});
}

# Heir
my $new_app = NewTestApplication->new();

$accessors = {
    %$accessors,
    'qbit_rbac' => {
        'accessor' => 'qbit_rbac',
        'app_pkg'  => 'NewTestApplication',
        'init'     => TRUE,
        'package'  => 'QBit::Application::Model::RBAC',
    },
};

$models = $new_app->get_models();

cmp_deeply($models, $accessors, 'heir accessors');

is(!!$new_app->can('qbit_rbac'), 1, 'exists method "qbit_rbac"');

is(ref($new_app->qbit_rbac), 'QBit::Application::Model::RBAC', 'Class name for "qbit_rbac" correctly');

# Check first app
is($app->can('qbit_rbac'), undef, 'not exists method "qbit_rbac" in app');

$models = $app->get_models();

delete($accessors->{'qbit_rbac'});

cmp_deeply($models, $accessors, 'accessors first app');

done_testing();
