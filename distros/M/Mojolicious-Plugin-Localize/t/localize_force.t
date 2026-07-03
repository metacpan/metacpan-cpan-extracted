#!usr/bin/env perl
use lib '../lib';
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t = Test::Mojo->new;
my $app = $t->app;

my $lang = [qw/pl de en/];

my $languages = sub  { $lang };

plugin Localize => {
  dict => {
    Lang => {
      _ => $languages,
      -en => {
        de => 'German',
        en => 'English'
      },
      de => {
        de => 'Deutsch',
        en => 'Englisch'
      }
    }
  }
};

is(app->loc('Lang__de'), 'Deutsch', 'Force preferred key');
is(app->loc('Lang__en'), 'Englisch', 'Force preferred key');

$lang = undef;

is(app->loc('Lang__de'), 'German', 'Force default key');
is(app->loc('Lang__en'), 'English', 'Force default key');



done_testing;
__END__
