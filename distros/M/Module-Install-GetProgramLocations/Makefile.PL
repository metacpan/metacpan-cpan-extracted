#/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use inc::Module::Install;

all_from('lib/Module/Install/GetProgramLocations.pm');

auto_set_bugtracker;
githubmeta;

requires(
  'Module::Install' => 0, 
  'File::Spec' => 0,
  'Cwd' => 0,
  'Sort::Versions' => 0,
);

test_requires(
  'IO::CaptureOutput' => 0,
  'Test::More' => 0,
);

license 'gpl2';
auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

WriteAll();
