#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use IO::Barf qw(barf);
use NKC::Transform::BIBFRAME2MARC::Utils qw(list_versions);

# Temporary directory.
my $temp_dir = tempdir(CLEANUP => 1);

# Create test files.
barf(catfile($temp_dir, 'bibframe2marc-2.5.0.xsl'), '');
barf(catfile($temp_dir, 'bibframe2marc-2.6.0.xsl'), '');
barf(catfile($temp_dir, 'bibframe2marc-3.6.0.xsl'), '');

# List versions.
my @versions = list_versions($temp_dir);

# Print versions.
print join "\n", @versions;
print "\n";

# Output:
# 2.5.0
# 2.6.0
# 3.6.0