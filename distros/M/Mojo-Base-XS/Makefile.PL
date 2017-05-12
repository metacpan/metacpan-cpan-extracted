use inc::Module::Install;

name 'Mojo-Base-XS';
all_from 'lib/Mojo/Base/XS.pm';
author q{Yaroslav Korshak <yko@cpan.org>};
license 'perl';

perl_version '5.010';

requires 'XSLoader';
test_requires 'Test::More';

resources
  license    => "http://dev.perl.org/licenses",
  bugtracker => 'http://github.com/yko/mojo-base-xs/issues',
  repository => "http://github.com/yko/mojo-base-xs";

auto_install;

author_tests "xt";

WriteAll;
