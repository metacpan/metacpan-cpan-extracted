#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 7;

@ARGV = (
  '--mode', 'uptime',
  '--statefilesdir', '/tmp',
  '--timeout', '1000',
  '--method', 'sqlplus',
  '--hostname', 'wbsrv',
  '--username', 'ibins',
  '--password', 'adrummfotznkonnsdhom',
  '--extra-opts', 'webdb@t/etc/mysql-dbs.ini',
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
$plugin->add_arg(
    spec => 'hostname=s',
    help => "--hostname
   the database server",
    default => 'localhost',
    required => 0,
);
$plugin->add_arg(
    spec => 'username=s',
    help => "--username
   the mysql user",
    required => 0,
);
$plugin->add_arg(
    spec => 'method=s',
    help => "--method",
    default => 'mysql',
    required => 0,
);
$plugin->add_arg(
    spec => 'password=s',
    help => "--password
   the mssql user's password",
    required => 0,
);

$plugin->add_default_args();
$plugin->getopts();
$plugin->override_opt("mode", "uptime");
$plugin->validate_args();

diag($plugin->statefilesdir());
diag($plugin->create_statefile());
ok($plugin, 'Monitoring::GLPlugin->new');
diag("module loaded");
ok($plugin->opts->method eq "mysql");
ok($plugin->opts->hostname eq "wwwsrv8.naprax.de");
ok($plugin->opts->password eq "pfu1de1fl");
ok($plugin->opts->statefilesdir eq "/var/tmp/testtest");
ok($plugin->opts->name eq "saxndi");

