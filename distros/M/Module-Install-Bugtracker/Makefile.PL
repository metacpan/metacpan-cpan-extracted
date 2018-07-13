#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;

include 'Module::AutoInstall';
name 'Module-Install-Bugtracker';
all_from 'lib/Module/Install/Bugtracker.pm';
readme_from_pod;
readme_markdown_from_pod;
auto_set_homepage;
auto_set_bugtracker;
auto_set_repository;
requires 'Module::Install';

# Perl 5.6 doesn't work with URI::Escape. We get an error about Exporter not exporting "import"
perl_version '5.008';

requires 'URI::Escape';

test_requires(
  'Test::More' => '1.001002',
);

use_standard_tests;
extra_tests;

author_requires 'Test::Compile';
author_requires 'Test::Perl::Critic';
author_requires 'Test::Pod';
author_requires 'Test::Spelling';
author_requires 'Pod::Wordlist::hanekomu';
author_requires 'Test::Pod::Coverage';
#author_requires 'Test::Kwalitee';  # # Attempt to free unreferenced scalar
author_requires 'Test::YAML::Meta';
author_requires 'Test::Portability::Files';
author_requires 'Test::Synopsis';

auto_install;

auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

realclean_files('inc');

WriteAll;

# ---- Workaround for broken module ----
# https://rt.cpan.org/Ticket/Display.html?id=125772
{
  package Module::Install::StandardTests;

  sub write_standard_test_compile {
      my $self = shift;
      $self->write_test_file('000_standard__compile.t', q/
          BEGIN {
            if ($^O eq 'MSWin32') {
              require Test::More;
              Test::More->import(skip_all =>
                  "Test::Compile doesn't work properly on Windows");
            } else {
              require Test::More;
              Test::More->import();
              eval "use Test::Compile";
              Test::More->builder->BAIL_OUT(
                  "Test::Compile required for testing compilation") if $@;
              all_pm_files_ok();
            }
          }
      /);
  }
}
