use Mojolicious::Lite;

use Test::More;
use Test::Mojo::WithRoles qw/Phantom/;

any '/' => 'index';

my $t = Test::Mojo::WithRoles->new;

my @messages;
sub console {
  push @messages, @_;
}

my $opts = { setup => <<'SETUP' };
  page.onConsoleMessage = function(msg) {
    perl('console', msg);
  }
SETUP

$t->phantom_ok('/' => <<'JS', $opts);
  page.evaluate(function(){
    console.log('test message');
  });
  perl.ok(1, 'dummy test');
JS


my $expect = ['startup message', 'test message' ];
is_deeply \@messages, $expect, 'got expected console messages';

done_testing;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
  <head></head>
  <body>
    Dummy
    %= javascript begin
      console.log('startup message');
    % end
  </body>
</html>
