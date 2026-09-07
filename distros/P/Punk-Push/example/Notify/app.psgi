#!/usr/bin/env perl

use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";

# Punk::Push is not installed while the distribution is being written, so run
# the demo against its build directory. Drop this line once it is on CPAN.
use lib "$FindBin::Bin/../../blib/lib";

# config/punk.yml carries relative paths (root/templates, root/static), so the
# process has to start from the application root for them to resolve. Doing it
# here rather than asking the operator to remember means `plackup app.psgi`
# works from anywhere.
#
# In BEGIN, because `use` below is itself compile-time: the application class
# loads its configuration as it compiles, which is before any statement out
# here would have run.
BEGIN {
    chdir $FindBin::Bin or die "cannot chdir to $FindBin::Bin: $!\n";
}

use Notify;

Notify->to_app;
