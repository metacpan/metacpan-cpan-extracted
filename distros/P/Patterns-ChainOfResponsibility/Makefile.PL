#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

all_from 'lib/Patterns/ChainOfResponsibility.pod';
requires 'Moose' => '1.21';
requires 'MooseX::Role::Parameterized' => '0.23',
test_requires 'Test::More' => '0.96';

require 'maint/Makefile.PL.include'
  if $Module::Install::AUTHOR;

WriteAll;

