use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Plack-Middleware-BlockHeaderInjection';
all_from 'lib/Plack/Middleware/BlockHeaderInjection.pm';
license  'artistic_2';

perl_version 5.010;

tests_recursive('t');
# tests_recursive('xt');

resources (
   homepage   => 'http://rrwo.tumblr.com',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/robrwo/Plack-Middleware-BlockHeaderInjection.git',
   bugtracker => 'https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection/issues',
);

configure_requires ();

build_requires (
   'Test::More' => 0,
);

requires (
    'Plack::Middleware'     => 0,
    'Plack::Util'           => 0,
    'Plack::Util::Accessor' => 0,
    'version'               => 0.77,
);

test_requires (
    'HTTP::Request'   => 0,
    'Plack::Builder'  => 0,
    'Plack::Request'  => 0,
    'Plack::Response' => 0,
    'Plack::Test'     => 0,
    'Test::More'      => 0,
);

install_as_cpan;
auto_install;
WriteAll;
