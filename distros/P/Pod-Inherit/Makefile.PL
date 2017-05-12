#!/usr/bin/perl

# I certainly make no guarantee that this will run on 5.6.0, but I can
# guarantee that it certianly will not work on anything older.  Every
# reasonable effort is made to make it work on 5.8 -- however, you'll
# get better warnings in some cases when running under 5.10.
use 5.006;

use inc::Module::Install;
use warnings;
use strict;

# Define metadata
name           'Pod-Inherit';
perl_version   '5.008001';
all_from       'lib/Pod/Inherit.pm';

# Specific dependencies
requires(
  'MRO::Compat'    => 0,
  'Path::Class'    => 0.31,
  'Pod::POM'       => 0,
  'Sub::Identify'  => 0,
  'Class::Load'    => 0,
  'List::AllUtils' => 0,
);
test_requires(
  'Module::CoreList'    => 0,
  'Test::Differences'   => 0,
  'Test::Exception'     => 0,
  'Test::More'          => 0,
  'Test::NoWarnings'    => 0,
  'Test::Pod::Coverage' => 0,
  'Test::Pod'           => 0,
  'Test::Warn'          => 0,
  'Test::EOL'           => 0,
);

WriteAll;
