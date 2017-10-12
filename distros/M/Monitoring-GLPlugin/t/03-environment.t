#!perl
use 5.006;
use strict;
use warnings;
use File::Basename;
use Test::More;
$ENV{PATH} = dirname($0);

plan tests => 4;

push(@INC,
    '/home/lausser/git/GLPlugin/blib/lib',
    '/home/lausser/git/GLPlugin/blib/arch'
);
require Monitoring::GLPlugin;
my $dummynousedonlyoncedrecksmeldung = $Monitoring::GLPlugin::survive_sudo_env;

@ARGV = (
  '--mode', 'uptime',
  '--statefilesdir', '/tmp',
  '--timeout', '1000',
  '--environment', 'TESTTHEENV=testenv',
  '--environment', 'LD_LIBRARY_PATH=/tmp',
  '--environment', 'TZ='.$ENV{TZ},
  '--environment', 'PATH='.dirname($0),
  '--multiline',
  '--runas', 'knarsch',
  #'-vvvvvvvvvvvvvvvvvvvvvvvv',
);
my $plugin = Monitoring::GLPlugin->new(
    shortname => '',
    usage => 'Usage: %s [ -v|--verbose ] [ -t <timeout> ] '.
        '  ...]',
    version => '$Revision: #PACKAGE_VERSION# $',
    blurb => 'This plugin checks nothing ',
    url => 'http://labs.consol.de/nagios/',
    timeout => 60,
);
$plugin->add_mode(
    internal => 'device::uptime',
    spec => 'uptime',
    alias => undef,
    help => 'Check the uptime of the device',
);

$plugin->add_default_args();
#$plugin->getopts();
$Monitoring::GLPlugin::plugin->getopts();
my $needs_restart = 0;
my @restart_opts = ();

if ($plugin->opts->environment) {
  # wenn die gewuenschten Environmentvariablen sich von den derzeit
  # gesetzten unterscheiden, dann restart. Denn $ENV aendert
  # _nicht_ das Environment des laufenden Prozesses.
  # $ENV{ZEUGS} = 1 bedeutet lediglich, dass $ENV{ZEUGS} bei weiterer
  # Verwendung 1 ist, bedeutet aber _nicht_, dass diese Variable
  # im Environment des laufenden Prozesses existiert.
  foreach (keys %{$plugin->opts->environment}) {
    if ((! $ENV{$_}) || ($ENV{$_} ne $plugin->opts->environment->{$_})) {
      $needs_restart = 1;
      $ENV{$_} = $plugin->opts->environment->{$_};
      $plugin->debug(sprintf "new %s=%s forces restart\n", $_, $ENV{$_});
    }
  }
}
if ($plugin->opts->runas) {
  # exec sudo $0 ... und dann ohne --runas
  $needs_restart = 1;
  # wenn wir environmentvariablen haben, die laut survive_sudo_env als
  # wichtig erachtet werden, dann muessen wir die ueber einen moeglichen
  # sudo-aufruf rueberretten, also in zusaetzliche --environment umwandenln.
  # sudo putzt das Environment naemlich aus.
  foreach my $survive_env (@{$Monitoring::GLPlugin::survive_sudo_env}) {
    if ($ENV{$survive_env} && ! scalar(grep { /^$survive_env=/ }
        keys %{$plugin->opts->environment})) {
      $plugin->opts->environment->{$survive_env} = $ENV{$survive_env};
      printf STDERR "add important --environment %s=%s\n",
          $survive_env, $ENV{$survive_env} if $plugin->opts->verbose >= 2;
      push(@restart_opts, '--environment');
      push(@restart_opts, sprintf '%s=%s',
          $survive_env, $ENV{$survive_env});
    }
  }
}
if ($needs_restart) {
  foreach my $option (keys %{$plugin->opts->all_my_opts}) {
    # der fliegt raus, sonst gehts gleich wieder in needs_restart rein
    next if $option eq "runas";
    foreach my $spec (map { $_->{spec} } @{$Monitoring::GLPlugin::plugin->opts->{_args}}) {
      if ($spec =~ /^(\w+)=(.*)/) {
        if ($1 eq $option && $2 =~ /s%/) {
          foreach (keys %{$plugin->opts->$option()}) {
            push(@restart_opts, sprintf "--%s", $option);
            push(@restart_opts, sprintf "%s=%s", $_, $plugin->opts->$option()->{$_});
          }
        } elsif ($1 eq $option) {
          push(@restart_opts, sprintf "--%s", $option);
          push(@restart_opts, sprintf "%s", $plugin->opts->$option());
        }
      } elsif ($spec eq $option) {
        push(@restart_opts, sprintf "--%s", $option);
      }
    }
  }
}
ok($ENV{TESTTHEENV} eq "testenv"); # is simply set
ok(grep /LD_LIBRARY_PATH=\/tmp/, @restart_opts); # is set as a surviving paramater
ok(! grep /runas/, @restart_opts);
ok($plugin->opts->runas eq "knarsch");

