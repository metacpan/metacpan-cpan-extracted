sub author_tests        { }
sub readme_from         { }
sub github              { }
sub auto_set_repository { }

use inc::Module::Install;
name('Net-AppNotifications');
all_from('lib/Net/AppNotifications.pm');

include('Module:AutoInstall');

requires('Find::Lib');
requires('AnyEvent');
requires('AnyEvent::HTTP');
requires('URI');

build_requires('Test::More');
auto_include_deps();
author_tests('xt');
auto_set_repository();
githubmeta();
WriteAll();
