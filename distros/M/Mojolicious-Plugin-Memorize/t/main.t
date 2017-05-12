use Mojolicious::Lite;

plugin 'Memorize';

get '/' => 'index';

use Test::More;
use Test::Mojo;
use Mojo::Util;

my $t = Test::Mojo->new;


$t->get_ok('/', 'first render');
my $time = $t->tx->res->dom('p')->map('text')->join('');
like $time, qr/^[.\d]+$/, 'time rendered';

sleep 2;
isnt Mojo::Util::steady_time, $time, 'time has advanced';

$t->get_ok('/')
  ->text_is( p => $time, 'template memorized' );

ok exists $t->app->memorize->cache->{test}, 'memorized content found by key';

$t->app->memorize->expire('test');

$t->get_ok('/')
  ->text_isnt( p => $time, 'memorized template manually expired' );

done_testing;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head></head>
<body>
% my $time = Mojo::Util::steady_time;
%= memorize test => begin
  %= tag p => $time
% end
</body>
</html>
