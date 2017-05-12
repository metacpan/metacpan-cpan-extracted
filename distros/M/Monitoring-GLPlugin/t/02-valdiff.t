#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 54;

push(@INC,
    '/home/lausser/git/GLPlugin/blib/lib',
    '/home/lausser/git/GLPlugin/blib/arch'
);
require Monitoring::GLPlugin;

@ARGV = (
  '--mode', 'uptime',
  '--statefilesdir', '/tmp',
  '--timeout', '1000',
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
$plugin->getopts();
$plugin->override_opt("mode", "uptime");
$plugin->validate_args();

sub clean_plugin {
  my @elements = @_;
  map {
      delete $plugin->{'delta_'.$_};
      delete $plugin->{$_.'_per_sec'};
      delete $plugin->{'delta_found_'.$_};
      delete $plugin->{'delta_lost_'.$_};
  } @elements;
  delete $plugin->{delta_timestamp};
}

diag("statefile is ".$plugin->create_statefile(name => 'test'));
diag("now test ever growing metrics. shrinking means overrun");
unlink $plugin->create_statefile(name => 'test')
    if -f $plugin->create_statefile(name => 'test');
$plugin->{metric} = 0;
$plugin->valdiff({name => 'test'}, qw(metric));
ok(exists $plugin->{delta_metric}, 'delta_metric was created');
ok($plugin->{delta_metric} == 0, 'delta_metric is 0');
$plugin->{metric} = 10;
$plugin->valdiff({name => 'test'}, qw(metric));
ok($plugin->{delta_metric} == 10, 'delta_metric is 10');
$plugin->{metric} = 5;
$plugin->valdiff({name => 'test'}, qw(metric));
ok($plugin->{delta_metric} == 5, 'delta_metric is 5, overrun');
clean_plugin(qw(metric));

diag("now test growing and shrinking metrics");
unlink $plugin->create_statefile(name => 'test', lastarray => 1)
    if -f $plugin->create_statefile(name => 'test', lastarray => 1);
$plugin->{metric} = 0;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
ok(exists $plugin->{delta_metric}, 'delta_metric was created');
ok($plugin->{delta_metric} == 0, 'delta_metric is 0');
sleep 1;
$plugin->{metric} = 10;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
ok($plugin->{delta_metric} == 10, 'delta_metric is 10');
sleep 1;
$plugin->{metric} = 5;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
diag("delta ". $plugin->{delta_metric});
ok($plugin->{delta_metric} == -5, 'delta_metric is -5');
clean_plugin(qw(metric));

diag("now test growing and shrinking metrics, compare to a value in the past");
#
# example: check the number of wlan access points managed by a controller
#          5 APs disappear (stolen?) and you don't want to use a volatile check
#          keep the critical state for a certain time
#
$plugin->override_opt("lookback", "10");
unlink $plugin->create_statefile(name => 'test', lastarray => 1)
    if -f $plugin->create_statefile(name => 'test', lastarray => 1);
$plugin->{metric} = 10;
my $tentime = time;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
ok(exists $plugin->{delta_metric}, 'delta_metric was created');
ok($plugin->{delta_metric} == 10, 'delta_metric is 10');
sleep 1;
diag("suddenly count is only 5");
$plugin->{metric} = 5;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
ok($plugin->{delta_metric} == -5, 'delta_metric is -5');
diag("delta -5 must be the result for the next 10 seconds");
sleep 5;
$plugin->{metric} = 5;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
ok($plugin->{delta_metric} == -5, 'delta_metric is still -5');
sleep 2;
$plugin->{metric} = 5;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
ok($plugin->{delta_metric} == -5, 'delta_metric is still -5');
foreach (1..12) {
  last if (time > $tentime+10);
  sleep 1;
}
sleep 1;
$plugin->{metric} = 5;
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric));
diag(sprintf "after %ds delta is %d", time - $tentime, $plugin->{delta_metric});
ok($plugin->{delta_metric} == 0, 'delta_metric is 0');
$plugin->override_opt("lookback", undef);
clean_plugin(qw(metric));



diag("now test growing and shrinking metrics");
diag("now test growing and shrinking lists");
unlink $plugin->create_statefile(name => 'test', lastarray => 1)
    if -f $plugin->create_statefile(name => 'test', lastarray => 1);
$plugin->{metric} = 5;
$plugin->{list} = ["ELEM1", "ELEM2", "ELEM3", "ELEM4", "ELEM5"];
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
ok(exists $plugin->{delta_metric}, 'delta_metric was created');
ok($plugin->{delta_metric} == 5, 'delta_metric is 5');
ok(scalar(@{$plugin->{delta_found_list}}) == 5, 'delta_found_list is 5');
ok(scalar(@{$plugin->{delta_lost_list}}) == 0, 'delta_lost_list is 0');
sleep 1;
$plugin->{metric} = 3;
$plugin->{list} = ["ELEM1", "ELEM3", "ELEM5"];
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
diag("delta ". $plugin->{delta_metric});
ok($plugin->{delta_metric} == -2, 'delta_metric is -2');
ok(scalar(grep /ELEM1/, @{$plugin->{list}}) != 0);
ok(scalar(grep /ELEM1/, @{$plugin->{delta_found_list}}) == 0);
ok(scalar(grep /ELEM1/, @{$plugin->{delta_lost_list}}) == 0);
ok(scalar(grep /ELEM2/, @{$plugin->{list}}) == 0);
ok(scalar(grep /ELEM2/, @{$plugin->{delta_found_list}}) == 0);
ok(scalar(grep /ELEM2/, @{$plugin->{delta_lost_list}}) != 0);
sleep 1;
$plugin->{metric} = 3;
$plugin->{list} = ["ELEM1", "ELEM2", "ELEM3"];
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
diag("delta ". $plugin->{delta_metric});
ok($plugin->{delta_metric} == 0, 'delta_metric is 0');
ok(scalar(grep /ELEM1/, @{$plugin->{list}}) != 0);
ok(scalar(grep /ELEM1/, @{$plugin->{delta_found_list}}) == 0);
ok(scalar(grep /ELEM1/, @{$plugin->{delta_lost_list}}) == 0);
ok(scalar(grep /ELEM2/, @{$plugin->{list}}) != 0);
ok(scalar(grep /ELEM2/, @{$plugin->{delta_found_list}}) != 0);
ok(scalar(grep /ELEM2/, @{$plugin->{delta_lost_list}}) == 0);
ok(scalar(grep /ELEM5/, @{$plugin->{list}}) == 0);
ok(scalar(grep /ELEM5/, @{$plugin->{delta_found_list}}) == 0);
ok(scalar(grep /ELEM5/, @{$plugin->{delta_lost_list}}) != 0);
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
ok($plugin->{delta_metric} == 0, 'delta_metric is unchanged');
ok(scalar(@{$plugin->{delta_found_list}}) == 0, 'delta_found_list is empty');
ok(scalar(@{$plugin->{delta_lost_list}}) == 0, 'delta_lost_list is empty');
clean_plugin(qw(metric list));

diag("now test growing and shrinking metrics, compare to a value in the past");
diag("now test growing and shrinking lists, compare to a list in the past");
$plugin->override_opt("lookback", "10");
unlink $plugin->create_statefile(name => 'test', lastarray => 1)
    if -f $plugin->create_statefile(name => 'test', lastarray => 1);
$plugin->{metric} = 5;
$plugin->{list} = ["ELEM1", "ELEM2", "ELEM3", "ELEM4", "ELEM5"];
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
ok(exists $plugin->{delta_metric}, 'delta_metric was created');
ok($plugin->{delta_metric} == 5, 'delta_metric is 5');
ok(scalar(@{$plugin->{delta_found_list}}) == 5, 'delta_found_list is 5');
ok(scalar(@{$plugin->{delta_lost_list}}) == 0, 'delta_lost_list is 0');
clean_plugin(qw(metric list));
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
sleep 11;
clean_plugin(qw(metric list));
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
sleep 1;
$tentime = time;
$plugin->{metric} = 3;
$plugin->{list} = ["ELEM1", "ELEM2", "ELEM3"];
diag("state change, ELEM4 and ELEM5 lost");
clean_plugin(qw(metric list));
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
ok($plugin->{delta_metric} == -2, 'delta_metric is -2');
ok(scalar(@{$plugin->{delta_found_list}}) == 0, 'delta_found_list is 0');
ok(scalar(@{$plugin->{delta_lost_list}}) == 2, 'delta_lost_list is 2');
sleep 1;
diag("should still be the same");
clean_plugin(qw(metric list));
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
ok($plugin->{delta_metric} == -2, 'delta_metric is -2');
ok(scalar(@{$plugin->{delta_found_list}}) == 0, 'delta_found_list is 0');
ok(scalar(@{$plugin->{delta_lost_list}}) == 2, 'delta_lost_list is 2');
sleep 1;
clean_plugin(qw(metric list));
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
ok($plugin->{delta_metric} == -2, 'delta_metric is -2');
ok(scalar(@{$plugin->{delta_found_list}}) == 0, 'delta_found_list is 0');
ok(scalar(@{$plugin->{delta_lost_list}}) == 2, 'delta_lost_list is 2');
foreach (1..12) {
  last if (time > $tentime+10);
  sleep 1;
  $plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
}
sleep 1;
clean_plugin(qw(metric list));
$plugin->valdiff({name => 'test', lastarray => 1}, qw(metric list));
ok($plugin->{delta_metric} == 0, 'delta_metric is 0');
ok(scalar(@{$plugin->{delta_found_list}}) == 0, 'delta_found_list is 0');
ok(scalar(@{$plugin->{delta_lost_list}}) == 0, 'delta_lost_list is 0');
diag(sprintf "after %ds delta is %d", time - $tentime, $plugin->{delta_metric});

