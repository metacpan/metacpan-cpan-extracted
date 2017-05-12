use strict;
use warnings;
use inc::Module::Install;

name('MozRepl');
author('Toru Yamaguchi <zigorou@cpan.org>');
abstract_from('lib/MozRepl.pm');
version_from('lib/MozRepl.pm');
license('perl');

requires('Carp::Clan');
requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('Data::Dump');
requires('Data::JavaScript::Anon');
requires('File::Spec');
requires('Module::Pluggable::Fast');
requires('Net::Telnet');
requires('Template');
requires('Template::Provider::FromDATA');
requires('Text::SimpleTable');
requires('UNIVERSAL::require');
requires('URI');

use_test_base;

auto_include;
auto_install;

WriteAll;
