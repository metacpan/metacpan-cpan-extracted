use 5.006;
use strict;
use warnings;
use inc::Module::Install;

name        'Role-Markup-XML';
abstract    'Bolt-on lazy XML generation';
readme_from 'lib/Role/Markup/XML.pm';
all_from    'lib/Role/Markup/XML.pm';
author      q{Dorian Taylor <dorian@cpan.org>};
license     'apache';

perl_version 5.010;

tests_recursive('t');

resources (
   homepage   => 'http://doriantaylor.com/',
   #IRC        => 'irc://irc.perl.org/#Role-Markup-XML',
   license    => 'http://www.apache.org/licenses/LICENSE-2.0',
   repository => 'git://github.com/doriantaylor/p5-role-markup-xml.git',
   #repository => 'https://bitbucket.org/Dorian Taylor/Role-Markup-XML',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Role-Markup-XML',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    Moo                    => 2.000001,
    'namespace::autoclean' => 0.28,
    'XML::LibXML'          => 2.0116,
);

install_as_cpan;
auto_install;
WriteAll;
