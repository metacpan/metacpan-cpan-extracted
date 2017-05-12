use inc::Module::Install;

name 'Nagios-Plugin-CheckHost';
all_from 'lib/Nagios/Plugin/CheckHost.pm';
install_script 'script/checkhost_ping';
install_script 'script/checkhost_http';

requires 'Carp';
requires 'List::Util';
requires 'LWP::UserAgent';
requires 'Monitoring::Plugin';
requires 'Test::More' => '0.88';
requires 'Try::Tiny';
requires 'Class::Load';
requires 'JSON';
requires 'URI';

tests 't/*.t';

resources
  bugtracker => 'https://github.com/und3f/nagios-plugin-checkhost/issues',
  repository => 'http://github.com/und3f/nagios-plugin-checkhost';

WriteAll;
