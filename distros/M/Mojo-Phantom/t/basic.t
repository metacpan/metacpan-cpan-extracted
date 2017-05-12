use Mojolicious::Lite;

any '/' => 'main';

use Test::More;
use Test::Mojo::WithRoles qw/Phantom/;

my $t = Test::Mojo::WithRoles->new;

ok 1, 'from mojo';

my $js = <<'JS';
  perl('ok', 1, 'ok from phantomjs');
  perl('is', status, 'success', 'status check');

  var text = page.evaluate(function(){
    return document.getElementsByTagName('p')[0].innerHTML;
  })

  perl.is(text, 'Goodbye', 'code evaluation');
JS

$t->phantom_ok('main', $js, {plan => 3});

done_testing;

__DATA__

@@ main.html.ep

<!DOCTYPE html>
<html>
  <head></head>
  <body>
    <p>Hello</p>
    %= javascript begin
      (function(){ document.getElementsByTagName('p')[0].innerHTML = 'Goodbye'; })();
    % end
  </body>
</html>

