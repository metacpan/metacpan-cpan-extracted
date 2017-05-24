#!/usr/bin/env perl
use strict;
use warnings;
use lib "."; # See RT:121831 - this fixes install on Perl 5.26+
use inc::Module::Install;

name 'Retry';
perl_version '5.008001';
all_from 'lib/Retry.pm';

requires 'Moo';
requires 'MooX::Types::MooseLike::Base';
build_requires 'Test::More' => 0.88;
build_requires 'Test::Exception';

resources 'repository' => 'http://github.com/TJC/Retry';
license 'artistic_2';

WriteAll;
