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

# Update: since 0.41, usage info is printed to stdout, not stderr.

use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Trap;

{
    package MyClass;
    use strict; use warnings;
    use Moose;
    with 'MooseX::Getopt';
}

# before fix, prints this on stderr:
#Unknown option: ?
#usage: test1.t

# after fix, prints this on stdout (formerly stderr):
#usage: test1.t [-?] [long options...]
#	-? --usage --help  Prints this usage information.

my $obj = MyClass->new_with_options;
ok($obj->meta->has_attribute('usage'), 'class has usage attribute');
isa_ok($obj->usage, 'Getopt::Long::Descriptive::Usage');
my $usage_text = $obj->usage->text;

foreach my $args ( ['--help'], ['--usage'], ['--?'], ['-?'], ['-h'] )
{
    local @ARGV = @$args;
    note "Setting \@ARGV to @$args";

    trap { MyClass->new_with_options() };

    is($trap->leaveby, 'exit', 'bailed with an exit code');
    is($trap->exit, 0, '...of 0');
    is(
        $trap->stdout,
        $usage_text,
        'Usage information printed to STDOUT',
    );
    is($trap->stderr, '', 'there was no STDERR output');
}

done_testing;
