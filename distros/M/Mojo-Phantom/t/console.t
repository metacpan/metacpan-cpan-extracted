use Test2::Bundle::Extended;
use Mojolicious::Lite;

any '/' => 'main';

use Test::Mojo::WithRoles qw/Phantom/;

my $t = Test::Mojo::WithRoles->new;

my $js = <<'JS';
  perl('ok', 1, 'one passing test');
  page.evaluate(function() {
    console.log('this is a console message');
  });
JS

is(
  intercept { $t->phantom_ok('main', $js, {plan => 1}) },
  array {
    event Note => sub {
      call message => 'Subtest: all phantom tests successful';
    };

    event Subtest => sub {
      call name => 'all phantom tests successful';
      call pass => 1;
      call effective_pass => 1;

      call subevents => array {
          event Plan => sub {
            call max => 1;
          };
          event Ok => sub {
            call name => 'one passing test';
            call pass => 1;
            call effective_pass => 1;
          };

          event Note => sub {
            call message => 'js console: this is a console message';
          };
          end();
      };
    };
    end();
  },
  'console log came through as note message',
);

is(
  intercept { $t->phantom_ok('main', $js, {plan => 1, note_console => 0}) },
  array {
    event Note => sub {
      call message => 'Subtest: all phantom tests successful';
    };

    event Subtest => sub {
      call name => 'all phantom tests successful';
      call pass => 1;
      call effective_pass => 1;

      call subevents => array {
          event Plan => sub {
            call max => 1;
          };
          event Ok => sub {
            call name => 'one passing test';
            call pass => 1;
            call effective_pass => 1;
          };

          end();
      };
    };
    end();
  },
  'console log came through as note message',
);


$js = <<'JS';
  perl('ok', 1, 'one passing test');
  console.log('this is a console message');
JS

is(
  intercept { $t->phantom_ok('main', $js, {plan => 1}) },
  array {
    event Note => sub {
      call message => 'Subtest: all phantom tests successful';
    };

    event Subtest => sub {
      call name => 'all phantom tests successful';
      call pass => 1;
      call effective_pass => 1;

      call subevents => array {
          event Plan => sub {
            call max => 1;
          };
          event Ok => sub {
            call name => 'one passing test';
            call pass => 1;
            call effective_pass => 1;
          };

          event Note => sub {
            call message => 'phantom console: this is a console message';
          };
          end();
      };
    };
    end();
  },
  'console log came through as note message',
);

is(
  intercept { $t->phantom_ok('main', $js, {plan => 1, note_console => 0}) },
  array {
    event Note => sub {
      call message => 'Subtest: all phantom tests successful';
    };

    event Subtest => sub {
      call name => 'all phantom tests successful';
      call pass => 1;
      call effective_pass => 1;

      call subevents => array {
          event Plan => sub {
            call max => 1;
          };
          event Ok => sub {
            call name => 'one passing test';
            call pass => 1;
            call effective_pass => 1;
          };
          end();
      };
    };
    end();
  },
  'console log came through as note message',
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

