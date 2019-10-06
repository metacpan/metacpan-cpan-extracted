use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;

$ENV{MOJO_MODE} = 'production';
plugin 'ModeHelpers';

ok app->in_prod, 'in_prod true when app in production';
ok !app->in_dev, 'in_dev false when app in production';

ok app->in_prod, 'in_prod true second time when app in production';
ok !app->in_dev, 'in_dev false second time when app in production';

done_testing;
