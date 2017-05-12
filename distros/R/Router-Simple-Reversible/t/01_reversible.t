use strict;
use warnings;
use Test::More;
use Router::Simple;

use_ok 'Router::Simple::Reversible';

my $router = Router::Simple::Reversible->new;

# from Router::Simple's pod
$router->connect('/', {controller => 'Root', action => 'show'});
$router->connect('/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'});
$router->connect('/wiki/:page', { controller => 'WikiPage', action => 'show' } );
$router->connect('/download/*.*', { controller => 'Download', action => 'file' } );

is $router->path_for({ controller => 'Root', action => 'show' }),
   '/';

is $router->path_for({ controller => 'Blog', action => 'monthly' }, { year => 2015, month => 10 }),
   '/blog/2015/10';

is $router->path_for({ controller => 'WikiPage', action => 'show' }, { page => 'HelloWorld' }),
   '/wiki/HelloWorld';

is $router->path_for({ controller => 'Download', action => 'file' }, { splat => [ 'path/to/file', 'xml' ] }),
   '/download/path/to/file.xml';

is $router->path_for({ controller => 'NoSuchController', action => 'show' }),
   undef;

done_testing;
