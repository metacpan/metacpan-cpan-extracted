use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Template/Plugin/Num2Word.pm';

requires
    "Lingua::Num2Word" => 0.07,
    "Lingua::EN::Numbers" => 1.01,
    "Template" => 2.20,
    "Template::Plugin::VMethods" => 0.003;

build_requires  'Test::More'        => '0.42';

tests 't/*.t';
author_tests 'xt/*.t';

WriteAll;


