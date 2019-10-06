use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;

$ENV{MOJO_MODE} = 'alpha';
plugin 'ModeHelpers';

ok !app->in_prod, 'in_prod false when app in custom mode';
ok app->in_dev, 'in_dev true when app in custom mode';

ok !app->in_prod, 'in_prod false second time when app in custom mode';
ok app->in_dev, 'in_dev true second time when app in custom mode';

done_testing;
