use 5.008;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'SQL-Abstract-More';
all_from 'lib/SQL/Abstract/More.pm';
author   q{Laurent Dami <dami@cpan.org>};
license  'artistic2';

perl_version 5.008;

tests_recursive('t');

resources (
   homepage   => 'https://metacpan.org/author/DAMI',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/damil/SQL-Abstract-More.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Abstract-More',
);

configure_requires (
  'Module::Install' => 0,
);

test_requires (
  'Test::More'          => 0,
  'Test::Exception'     => 0,
  'SQL::Abstract::Test' => 0,
  'List::MoreUtils'     => 0,
);


requires (
  'MRO::Compat'          => 0,
  'SQL::Abstract'        => 1.73,
  'Params::Validate'     => 0,
  'parent'               => 0,
  'namespace::clean'     => 0,
);

install_as_cpan;
auto_install;
WriteAll;
