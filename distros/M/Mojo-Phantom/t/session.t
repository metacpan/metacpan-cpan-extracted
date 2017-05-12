use Mojolicious::Lite;

use Test::More;
use Test::Mojo::WithRoles qw/Phantom/;

any '/set' => sub {
  my $c = shift;
  $c->session(val => 'pass');
  $c->render(text => 'set');
};

any '/get' => 'get';

my $t = Test::Mojo::WithRoles->new;
$t->get_ok('/set')
  ->status_is(200)
  ->content_is('set');

$t->phantom_ok('get', <<'JS');
  var text = page.evaluate(function(){
    return document.getElementsByTagName('p')[0].innerHTML;
  });

  perl.is(text, 'pass', 'cookie seen from phantom');
JS

done_testing;

__DATA__

@@ get.html.ep

<!DOCTYPE html>
<html>
<head></head>
<body>
  %= tag p => session('val') || 'fail';
</body>
</html>

