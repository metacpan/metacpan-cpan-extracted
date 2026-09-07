#!/usr/bin/env perl

use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";

# Punk::Challenge is not installed while the distribution is being written,
# so run the demo against its build directory. Drop these two lines once it
# is on CPAN and installed like anything else.
use lib "$FindBin::Bin/../../blib/lib", "$FindBin::Bin/../../blib/arch";

# config/punk.yml carries relative paths (root/templates, root/static), so
# the process has to start from the application root for them to resolve.
# Doing it here rather than asking the operator to remember means
# `plackup app.psgi` works from anywhere.
#
# In BEGIN, because `use` below is itself compile-time: the application
# class loads its configuration as it compiles, which is before any
# statement out here would have run.
BEGIN {
    chdir $FindBin::Bin or die "cannot chdir to $FindBin::Bin: $!\n";
}

use Gate;

Gate->to_app;
