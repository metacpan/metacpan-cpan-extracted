use 5.16.0;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Plack-Middleware-Timed-Logger';
all_from 'lib/Plack/Middleware/Timed/Logger.pm';
author   q{Nikolay Martynov <kolya@cpan.org>};
license  'perl';

perl_version '5.16.0';

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#Plack-Middleware-Timed-Logger',
   license    => 'http://dev.perl.org/licenses/',
   repository => 'git://github.com/mar-kolya/Plack-Middleware-Timed-Logger.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-Timed-Logger',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Data::Dump'          => 0,
   'Test::More'          => 0,
   'Test::Easy'          => 0,
   'Test::Exception'     => 0,
   'Test::Pod::Coverage' => 0,
   'Test::Pod'           => 0,
   'Test::CheckManifest' => 0,
);

requires (
   'Plack'         => 0,
   'Timed::Logger' => 0
);

install_as_cpan;
auto_install;
WriteAll;
