#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;

name 'MojoX-CPAN-Uploader';

all_from 'lib/MojoX/CPAN/Uploader.pm';
author 'Yaroslav Korshak <yko@cpan.org>';
abstract 'Mojo way to upload files to CPAN';
license 'perl';

perl_version '5.010';

requires 'Mojolicious'     => 1.51;
requires 'IO::Socket::SSL' => 1.43;
requires 'Term::ReadKey';
requires 'Getopt::Long';
requires 'File::Spec';
requires 'IPC::Open3';

test_requires 'Test::More';

tests 't/*.t t/*/*.t';

no_index directory => 't';
install_script 'bin/mojo-cpanup';

resources
  bugtracker => 'http://github.com/yko/mojox-cpan-uploader/issues',
  repository => 'http://github.com/yko/mojox-cpan-uploader',
  license    => 'http://dev.perl.org/licenses/';

auto_install;

makemaker_args(META_MERGE => {x_deprecated => 1});

WriteAll;
