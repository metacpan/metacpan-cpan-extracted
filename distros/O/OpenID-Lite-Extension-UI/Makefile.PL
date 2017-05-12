use strict;
use warnings;

use inc::Module::Install;

name 'OpenID-Lite-Extension-UI';
all_from 'lib/OpenID/Lite/Extension/UI.pm';

requires(
    'OpenID::Lite' => 0,
);

tests('t/*.t t/*/*.t');

#author_tests('xt');
test_requires(
    'Test::More' => 0,

    #    'Test::Class' => 0,
);

auto_include;
WriteAll;
