use strict;
use warnings;

use inc::Module::Install;

name 'OpenID-Lite-Extension-SREG';
all_from 'lib/OpenID/Lite/Extension/SREG.pm';

requires(
    'OpenID::Lite' => 0,
    'List::MoreUtils' => 0,
);

tests('t/*.t t/*/*.t');

#author_tests('xt');
test_requires(
    'Test::More' => 0,

    #    'Test::Class' => 0,
);

auto_include;
WriteAll;
