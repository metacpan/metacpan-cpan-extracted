#!/usr/bin/env perl

# The documentation claims:
#   If Getopt::Long::Descriptive is installed and any of the following command
#   line params are passed (--help, --usage, --?), the program will exit with
#   usage information...

# This is not actually true (as of 0.29), as:
# 1. the consuming class must set up a attributes named 'help', 'usage' and
#     '?' to contain these command line options, which is not clearly
#     documented as a requirement
# 2.  the code is checking whether an option was parsed into an attribute
#     *called* 'help', 'usage' or '?', not whether the option --help, --usage
#     or --? was passed on the command-line (the mapping could be different,
#     if cmd_flag or cmd_aliases is used),

# This inconsistency is the underlying cause of RT#52474, RT#57683, RT#47865.

use strict; use warnings;
use Test::More tests => 6;
use Test::Exception;

{
    package MyClass;
    use strict; use warnings;
    use Mouse;
    with 'MouseX::Getopt';
}

# before fix, prints this on stderr:
#Unknown option: ?
#usage: test1.t

# after fix, prints this on stderr:
#usage: test1.t [-?] [long options...]
#	-? --usage --help  Prints this usage information.

foreach my $args ( ['--help'], ['--usage'], ['--?'], ['-?'] )
{
    local @ARGV = @$args;

    throws_ok { MyClass->new_with_options() }
        qr/^usage: (?:[\d\w]+)\Q.t [-?] [long options...]\E.^\t\Q-? --\E(\[no-\])?usage --(\[no-\])?help\s+\QPrints this usage information.\E$/ms,
        'Help request detected; usage information properly printed';
}

# now call again, and ensure we got the usage info.
my $obj = MyClass->new_with_options();
ok($obj->meta->has_attribute('usage'), 'class has usage attribute');
isa_ok($obj->usage, 'Getopt::Long::Descriptive::Usage');

