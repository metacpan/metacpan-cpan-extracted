package Mojolicious::Plugin::TestRandomString;
use Mojo::Base 'Mojolicious::Plugin';

# Register Plugin
sub register {
  my ($plugin, $mojo) = @_;

  # Load random string plugin
  $mojo->plugin('Util::RandomString' => {
    chiffre => {
      alphabet => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
      entropy => 128
    }
  });

  $mojo->helper(
    chiffre => sub {
      shift->random_string('chiffre');
    }
  );

  my $x = $mojo->random_string('chiffre');
  $x = $mojo->random_string('chiffre');

  $mojo->routes->get('/testpath')->to(
    cb => sub {
      my $c = shift;
      return $c->render(text => $c->chiffre);
    }
  );
};

1;
