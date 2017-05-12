use Mojolicious::Lite;

use Test::More;
use Test::Mojo::WithRoles qw/Phantom/;

any '/' => 'index';

my $t = Test::Mojo::WithRoles->new;
$t->phantom_ok('/' => <<'JS');
  var text = page.evaluate(function(){
    return document.getElementById('name').innerHTML;
  });
  perl.is(text, 'Bender', 'name changed after loading');
JS

done_testing;

__DATA__

@@ index.html.ep

<!DOCTYPE html>
<html>
  <head></head>
  <body>
    <p id="name">Leela</p>
    <script>
      (function(){ document.getElementById('name').innerHTML = 'Bender' })();
    </script>
  </body>
</html>

