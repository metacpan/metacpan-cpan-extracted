#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

all_from 'lib/Module/Setup/Flavor/JJNAPIORK.pm';
require 'maint/Makefile.PL.include'
  unless -e 'META.yml';

requires 'Module::Setup' => '0.09';
test_requires 'Test::More' => '0.96';

WriteAll;
