use 5.010;
use strict;
use warnings;
use inc::Module::Install;

name     'Role-Kerberos';
readme_from 'lib/Role/Kerberos.pm';
abstract 'Bolt-on Kerberos ticket management';
all_from 'lib/Role/Kerberos.pm';
author   q{Dorian Taylor <dorian@cpan.org>};
license  'apache';

perl_version 5.010;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#Role-Kerberos',
   license    => 'http://www.apache.org/licenses/LICENSE-2.0',
   repository => 'git://github.com/doriantaylor/p5-role-kerberos.git',
   #repository => 'https://bitbucket.org/Dorian Taylor/Role-Kerberos',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Role-Kerberos',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

test_requires (
   'Term::ReadPassword' => 0,
);

requires (
    'Moo'              => '1.006',
# we don't actually import any symbols or eval anything
#    'namespace::clean' => '0.24',
#    'Try::Tiny'        => '0.22',
    'Authen::Krb5'     => '1.9',
);

install_as_cpan;
auto_install;
WriteAll;
