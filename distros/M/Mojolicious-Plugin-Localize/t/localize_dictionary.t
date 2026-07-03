#!usr/bin/env perl
use lib '../lib';
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t = Test::Mojo->new;
my $app = $t->app;

my $languages = sub  { [qw/pl en de/] };

plugin 'Localize' => {
  dict => {
    welcome => {
      _ => $languages,
      en => 'Welcome!'
    },
    MyPlugin => {
      _ => $languages,
      en => {
        welcome => 'Hello!',
      },
      de => {
        welcome => 'Hallo!'
      }
    }
  }
};

my $d = app->localize->dictionary;
is(${$d->{welcome}->{en}}, 'Welcome!', 'Welcome');
ok(!$d->{welcome}->{de}, 'No welcome');

plugin Localize => {
  dict => {
    welcome => {
      de => 'Willkommen!'
    }
  }
};

is(${$d->{welcome}->{en}}, 'Welcome!', 'Welcome');
is(${$d->{welcome}->{de}}, 'Willkommen!', 'No welcome');


done_testing;
__END__


app->localize->dictionary('MyPlugin');

