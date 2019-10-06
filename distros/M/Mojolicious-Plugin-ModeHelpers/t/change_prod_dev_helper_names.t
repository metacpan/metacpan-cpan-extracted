use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Lite;

throws_ok
    { plugin ModeHelpers => { prod_helper_name => undef, dev_helper_name => 'in_development_mode' } }
    qr /prod_helper_name must not be empty/,
    'undef prod_helper_name throws';

throws_ok
    { plugin ModeHelpers => { prod_helper_name => '', dev_helper_name => 'in_development_mode' } }
    qr /prod_helper_name must not be empty/,
    'blank prod_helper_name throws';

lives_ok
    { plugin ModeHelpers => { prod_helper_name => 0, dev_helper_name => 'in_development_mode' } }
    'non-blank but false prod_helper_name lives';

throws_ok
    { plugin ModeHelpers => { prod_helper_name => 'in_production_mode', dev_helper_name => undef } }
    qr /dev_helper_name must not be empty/,
    'undef prod_helper_name throws';

throws_ok
    { plugin ModeHelpers => { prod_helper_name => 'in_production_mode', dev_helper_name => '' } }
    qr /dev_helper_name must not be empty/,
    'blank dev_helper_name throws';

lives_ok
    { plugin ModeHelpers => { prod_helper_name => 'in_production_mode', dev_helper_name => 0 } }
    'non-blank but false dev_helper_name lives';

plugin ModeHelpers => { prod_helper_name => 'in_production_mode', dev_helper_name => 'in_development_mode' };

ok !app->in_production_mode, 'prod_helper named in_production_mode';
ok app->in_development_mode, 'dev_helper named in_development_mode';

ok !app->can('in_prod'), 'default in_prod helper does not exist';
ok !app->can('in_dev'), 'default in_dev helper does not exist';

plugin ModeHelpers => { prod_helper_name => 'modes.prod', dev_helper_name => 'modes.dev' };

ok !app->modes->prod, 'dot notation works for prod_helper_name';
ok app->modes->dev, 'dot notation works for dev_helper_name';

ok !app->can('in_prod'), 'default in_prod helper does not exist';
ok !app->can('in_dev'), 'default in_dev helper does not exist';

done_testing;
