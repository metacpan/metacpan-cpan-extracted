#!usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;
my $app = $t->app;

$ENV{MOJO_LOCALIZE_DEBUG} = 0;

my $languages = sub  { [qw/pl en de/] };

plugin Localize => {
  dict => {
    Nested => {
      _ => [qw/de fr en/],
      de => {
        bye => 'Auf Wiedersehen!',
        tree => {
          -sg => 'Baum'
        }
      },
      fr => {
        welcome => 'Bonjour!',
        bye => 'Au revoir!'
      },
      -en => {
        welcome => 'Welcome!',
        bye => 'Good bye!',
        tree => {
          _ => [qw/pl/],
          -sg => 'Tree',
          pl => 'Trees'
        }
      }
    }
  }
};


is(app->loc('Nested_de_bye'), 'Auf Wiedersehen!', 'Nested de');
is(app->loc('Nested_fr_bye'), 'Au revoir!', 'Nested fr');
is(app->loc('Nested_en_bye'), 'Good bye!', 'Nested en');

is(app->loc('Nested_fr_welcome'), 'Bonjour!', 'Nested fr');
is(app->loc('Nested_en_welcome'), 'Welcome!', 'Nested en');
is(app->loc('Nested_de_welcome'), '', 'Nested de - not there');

is(app->loc('Nested_welcome'), 'Bonjour!', 'Nested');
is(app->loc('Nested_tree'), 'Baum', 'Nested');

done_testing;
__END__
