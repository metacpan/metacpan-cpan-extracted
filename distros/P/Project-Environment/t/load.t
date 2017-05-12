# Project::Environment

use Test::Most;

use lib::abs './lib';

subtest 'use_ok' => sub {
    use_ok 'Project::Environment';
    use_ok 'ProjectX::Env';
    use_ok 'ProjectX::Direct';
};

subtest 'project_root used directly' => sub {
    my $pd = ProjectX::Direct->new;
    ok $pd->env, 'Build Project::Environment object successfully.';
    is $pd->env->project_environment, 'develop', 'Found project env directly.';
};

subtest 'project_environment' => sub {
    ok my $pe = ProjectX::Env->new, 'Got object.';
    is $pe->project_environment, 'develop', 'project_environment is develop';
    is "$pe", 'develop', 'stringify';
};

subtest 'explicit attribute set' => sub {
    ok my $pe = ProjectX::Env->new, 'Got object.';
    ok $pe = ProjectX::Env->new(project_environment => 'test'), 'Got object.';
    is $pe->project_environment, 'test',
        'Explicitly set project_environment.';
};

subtest 'alias' => sub {
    ok my $pe = ProjectX::Env->new, 'Got object.';
    is $pe->project_environment, $pe->environment, 'environment alias';
    is $pe->project_environment, $pe->env,         'env alias';
};

subtest 'env' => sub {
    local $ENV{PROJECT_ENVIRONMENT} = 'env';
    ok my $pe = ProjectX::Env->new, 'Got object.';
    is $pe->project_environment, $ENV{PROJECT_ENVIRONMENT},
        'Set project_environment via %ENV.';
};

subtest 'flyweight' => sub {
    ok my $pe = ProjectX::Env->instance, 'Got object via ->instance.';
    is $pe->project_environment, 'develop', 'project_environment is develop';
    local $ENV{PROJECT_ENVIRONMENT} = 'env';
    ok $pe = ProjectX::Env->instance, 'Got object via ->instance again.';
    is $pe->project_environment, 'develop',
        'project_environment is still develop (cached).';
};

done_testing;
