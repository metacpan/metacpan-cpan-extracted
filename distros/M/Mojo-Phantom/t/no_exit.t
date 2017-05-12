use Test2::Bundle::Extended;
use Mojolicious::Lite;

any '/' => 'main';

use Test::Mojo::WithRoles qw/Phantom/;

my $t = Test::Mojo::WithRoles->new;

my $js = <<'JS';
  setInterval(function() {
    perl.ok(1, "async ok");
    phantom.exit();
  });
  perl.ok(1, "normal ok");
JS

is(
  intercept { $t->phantom_ok('main', $js, {plan => 2, no_exit => 1}) },
  array {
    event Note => sub {
      call message => 'Subtest: all phantom tests successful';
    };

    event Subtest => sub {
      call name => 'all phantom tests successful';
      call pass => 1;

      call subevents => array {
        event Plan => sub {
          call max => 2;
        };

        event Ok => sub {
          call name => 'normal ok';
          call pass => 1;
        };

        event Ok => sub {
          call name => 'async ok';
          call pass => 1;
        };
        end();
      };
    };
    end();
  },
  'saw both async and non-async oks',
);

is(
  intercept { $t->phantom_ok('main', $js, {plan => 1}) },
  array {
    event Note => sub {
      call message => 'Subtest: all phantom tests successful';
    };

    event Subtest => sub {
      call name => 'all phantom tests successful';
      call pass => 1;

      call subevents => array {
        event Plan => sub {
          call max => 1;
        };

        event Ok => sub {
          call name => 'normal ok';
          call pass => 1;
        };
        end();
      };
    };
    end();
  },
  'saw both async and non-async oks',
);

done_testing;

__DATA__

@@ main.html.ep

<!DOCTYPE html>
<html>
  <head></head>
  <body>
  </body>
</html>

