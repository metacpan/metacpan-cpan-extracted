#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use inc::Module::Install;

all_from('lib/Module/Install/CustomInstallationPath.pm');

auto_set_bugtracker;
githubmeta;

requires(
  'Module::Install' => 0, 
  'File::HomeDir' => 0,
);

test_requires(
  'Test::More' => 0,
);

license 'gpl2';
auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

WriteAll();
