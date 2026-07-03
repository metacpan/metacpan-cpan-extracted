#!usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t = Test::Mojo->new;
my $app = $t->app;

my $lang = [qw/de en/];

plugin Localize => {
  dict => {
    _ =>  sub {
      $lang
    },
    -en => {
      welcome => 'Welcome'
    },
    de => {
      welcome => 'Willkommen'
    },
    MyApp => {
      _ => $lang,
      -pl => {
        welcome => 'Serdecznie witamy'
      }
    }
  }
};

is(app->localize->preference, 'de', 'Get preference');
is(app->localize->preference('MyApp'), 'pl', 'Get preference');


$lang = [qw/en de/];


is(app->localize->preference, 'en', 'Get preference');

plugin Localize => {
  dict => {
    MyApp => {
      de_welcome => 'Herzlich Willkommen!'
    }
  }
};

is(app->localize->preference('MyApp'), 'de', 'Get preference');

done_testing;
