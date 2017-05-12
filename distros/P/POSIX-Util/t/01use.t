#!/usr/bin/perl
use lib 'lib', 'blib/lib', 'blib/arch';

use warnings;
use strict;

use Test::More tests => 1;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/POSIX
    POSIX::1003
    Test::More
    XSLoader
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

require_ok('POSIX::Util');
