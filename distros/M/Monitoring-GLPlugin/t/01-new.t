#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

@ARGV = (
  '--mode', 'uptime',
  '--statefilesdir', '/tmp',
  '--timeout', '1000',
  #'-vvvvvvvvvvvvvvvvvvvvvvvv',
);

if ( ! grep /BEGIN/, keys %Monitoring::GLPlugin::) {
  eval {
    require Monitoring::GLPlugin;
    require Monitoring::GLPlugin::SNMP;
    require Monitoring::GLPlugin::UPNP;
  };
}
ok(grep /BEGIN/, keys %Monitoring::GLPlugin::, 'module loaded');

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

diag($Monitoring::GLPlugin::pluginname);
diag($plugin->statefilesdir());
diag($plugin->create_statefile());
ok($plugin, 'Monitoring::GLPlugin->new');
$plugin = undef;

$plugin = Monitoring::GLPlugin::SNMP->new(
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
# $plugin->getopts(); # no more command line left
$plugin->override_opt("mode", "uptime");
# $plugin->validate_args(); # would exit 3

diag($Monitoring::GLPlugin::pluginname);
diag($plugin->statefilesdir());
diag($plugin->create_statefile());
ok($plugin, 'Monitoring::GLPlugin::SNMP->new');


