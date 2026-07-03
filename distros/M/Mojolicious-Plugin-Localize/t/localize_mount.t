#!usr/bin/env perl
use Test::More;
use Test::Mojo;
use Mojolicious;
use Data::Dumper;

my $t = Test::Mojo->new(Mojolicious->new);
my $app = $t->app;

my $lang = [qw/pl de en/];
my $languages = sub  { $lang };


$app->plugin(Localize => {
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
});

is($app->loc('Lang__de'), 'Deutsch', 'Force preferred key');
is($app->loc('Lang__en'), 'Englisch', 'Force preferred key');

$lang = undef;

is($app->loc('Lang__de'), 'German', 'Force default key');
is($app->loc('Lang__en'), 'English', 'Force default key');

my $t2 = Test::Mojo->new(Mojolicious->new);
my $app2 = $t2->app;

$app2->plugin(Localize => {
  dict => {
    Lang => {
      _ => $languages,
      -de => {
        de => 'Deutsch'
      }
    }
  }
});

is($app2->loc('Lang__de'), 'Deutsch', 'Force preferred key');
ok(!$app2->loc('Lang__en'), 'Force preferred key');


done_testing;
__END__
