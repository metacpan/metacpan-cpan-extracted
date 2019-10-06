use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;

$ENV{MOJO_MODE} = 'development';
plugin 'ModeHelpers';

ok !app->in_prod, 'in_prod false when app not in production';
ok app->in_dev, 'in_dev true when app not in production';

ok !app->in_prod, 'in_prod false second time when app not in production';
ok app->in_dev, 'in_dev true second time when app not in production';

done_testing;
