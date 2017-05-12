#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;

name 'Mojolicious-Plugin-LinkedContent';
all_from 'lib/Mojolicious/Plugin/LinkedContent.pm';
author q{Yaroslav Korshak <yko@cpan.org>};
license 'perl';

requires 'Mojolicious' => 5.0;
test_requires 'Test::More';

perl_version '5.010';

resources
  license => "http://dev.perl.org/licenses",
  bugtracker =>
  'https://github.com/yko/mojolicious-plugin-linkedcontent/issues',
  repository => "https://github.com/yko/mojolicious-plugin-linkedcontent";

auto_install;

author_tests "xt";

WriteAll;
