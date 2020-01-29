
use Mojolicious::Lite;
use Mojo::File qw( curfile );
use lib curfile->dirname->sibling( "lib" )->to_string;

plugin 'AutoReload';

get '/' => 'index';

app->start;
__DATA__
@@ index.html.ep
<h1>Hello, World!</h1>
