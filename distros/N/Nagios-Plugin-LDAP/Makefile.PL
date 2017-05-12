use inc::Module::Install;

name           'Nagios-Plugin-LDAP';
author         'Graham Barr <gbarr@pobox.com>';
version_from   'lib/Nagios/Plugin/LDAP.pm';
abstract       'Nagios plugin to observe LDAP server';
license        'perl';

requires       'Carp';
requires       'Net::LDAP';
requires       'Nagios::Plugin';
requires       'Time::HiRes';
requires       'DateTime';

install_script "bin/check_ldap_repl";

auto_install_now();

WriteAll;
