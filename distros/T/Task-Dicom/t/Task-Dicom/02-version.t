# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Dicom;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Dicom::VERSION, 0.07, 'Version.');
