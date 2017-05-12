use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Sub/Alias.pm';

build_requires  'Test::More'        => '0.42';

requires 'Sub::Exporter';
requires 'Devel::BeginLift';
requires 'Devel::Declare';

tests 't/*.t';
author_tests 'xt/*.t';

WriteAll;
