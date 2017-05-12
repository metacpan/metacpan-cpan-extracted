#!/usr/bin/env perl
use inc::Module::Install;

name     'Template-Provider-Markdown';
all_from 'lib/Template/Provider/Markdown.pm';

requires
    'Text::Markdown' => 0,
    'Text::Diff' => 0,
    'Template' => 2.20;

build_requires  ('Test::More');

tests 't/*.t';
author_tests 'xt/*.t';

&auto_install;
&WriteAll;

