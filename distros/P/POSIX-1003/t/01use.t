#!/usr/bin/perl
use lib 'lib', 'blib/lib', 'blib/arch';

use warnings;
use strict;

use Test::More tests => 22;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/POSIX
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

require_ok('POSIX::1003::Module');
require_ok('POSIX::1003::Confstr');
require_ok('POSIX::1003::Errno');
require_ok('POSIX::1003::Fcntl');
require_ok('POSIX::1003::FdIO');
require_ok('POSIX::1003::FS');
require_ok('POSIX::1003::Limit');
require_ok('POSIX::1003::Locale');
require_ok('POSIX::1003::Math');
require_ok('POSIX::1003::OS');
require_ok('POSIX::1003::Pathconf');
require_ok('POSIX::1003::Proc');
require_ok('POSIX::1003::Properties');
require_ok('POSIX::1003::Signals');
require_ok('POSIX::1003::Sysconf');
require_ok('POSIX::1003::Termios');
require_ok('POSIX::1003::Time');
require_ok('POSIX::1003::User');
require_ok('POSIX::SigAction');
require_ok('POSIX::SigSet');

require_ok('POSIX::1003::Symbols');
require_ok('POSIX::1003');
