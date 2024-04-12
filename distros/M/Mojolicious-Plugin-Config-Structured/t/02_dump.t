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
  qq{db =>\n  user => "tyrrminal"\n},
  'check non-verbose dump'
);

is(
  capture_output(sub {Mojolicious::Plugin::Config::Structured::Command::config_dump::run(app, '--verbose')}),
  qq{/db/user\n  Type:       Str\n  Value:      "tyrrminal"\n\n},
  'check verbose dump'
);

done_testing;
