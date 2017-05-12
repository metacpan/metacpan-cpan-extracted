#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'Struct-Flatten-Template';
all_from 'lib/Struct/Flatten/Template.pm';
license 'artistic_2';

perl_version 5.008;

resources(
    homepage   => 'http://rrwo.tumblr.com',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'git://github.com/robrwo/Struct-Flatten-Template.git',
    bugtracker => 'https://github.com/robrwo/Struct-Flatten-Template/issues',
);

# configure_requires(
#     'Module::Install::AuthorTests' => 0.02,
# );

build_requires(
    'Test::Most'	=> 0,
    'Test::Differences' => 0,
);

requires(
    'Moose'                => 0,
    'namespace::autoclean' => 0,
    'Tie::RefHash'         => 0,
    'version'              => 0.77,
);

test_requires(
    'Test::Most'	=> 0,
    'Test::Differences' => 0,
);

tests_recursive('t');

# author_tests('xt');

install_as_cpan;
auto_install;
WriteAll;
