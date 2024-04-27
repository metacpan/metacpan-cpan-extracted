use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

use Mojolicious::Plugin::Config::Structured::Command::config_dump;

use experimental qw(signatures);

$ENV{ANSI_COLORS_DISABLED} = 1;
$ENV{MOJO_MODE}            = 'test';
$ENV{MOJO_HOME}            = "./t/conf";
app->home->detect;

app->moniker('TestApp2');
ok(lives {plugin 'Config::Structured'}, 'config loaded');

sub capture_output($cmd) {
  my $output;
  open(my $outputFH, '>', \$output) or die;
  my $oldFH = select $outputFH;
  $cmd->();
  close($outputFH);
  return $output;
}

is(
  capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app)}),
  qq{db =>\n  pass => "************"\n  user => "tyrrminal"\n},
  'check non-verbose dump'
);

is(
  capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app, '--reveal')}),
  qq{db =>\n  pass => "hunter2"\n  user => "tyrrminal"\n},
  'check non-verbose dump (reveal)'
);

is(
  capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app, '--verbose')}),
qq{/db/pass\n  Type:       Str\n  Sensitive:  Y\n  Value:      "************"\n\n/db/user\n  Type:       Str\n  Value:      "tyrrminal"\n\n},
  'check verbose dump'
);

is(
  capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app, '--verbose', '--reveal')}),
qq{/db/pass\n  Type:       Str\n  Sensitive:  Y\n  Value:      "hunter2"\n\n/db/user\n  Type:       Str\n  Value:      "tyrrminal"\n\n},
  'check verbose dump (reveal)'
);

is(capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app, '--path', '/db/user')}),
  qq{"tyrrminal"\n}, 'check leaf node dump');

is(capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app, '--path', '/db/pass')}),
  qq{"************"\n}, 'check sensitive leaf node dump');

is(capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app, '--path', '/db/pass', '--reveal')}),
  qq{"hunter2"\n}, 'check sensitive leaf node dump (reveal)');

done_testing;
