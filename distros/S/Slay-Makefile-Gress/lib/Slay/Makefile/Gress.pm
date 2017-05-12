package Slay::Makefile::Gress;

use Exporter;
use base Exporter;
@Slay::Makefile::Gress::EXPORT_OK = qw(do_tests);

use strict;
use warnings;

use File::Path qw(rmtree);
use File::Copy::Recursive qw(dircopy);

use Test::More;
use Carp;

use FindBin;
use lib "$FindBin::RealBin/../../tbin";
use Slay::Makefile 0.02;

our $VERSION = "0.08";

# $Id$

=head1 NAME

Slay::Makefile::Gress - Use Slay::Makefile for software regression testing

=head1 DESCRIPTION

This module provides support for running a set of regression tests
from a .t file by doing builds with a C<Slay::Makefile> file.

=head1 USAGE

To use this module, the .t file calling it should contain something like:

  use Slay::Makefile::Gress qw(do_tests);
  do_tests("SlayMakefile", @ARGV);

=head1 OVERVIEW

The basic functionality of this module is to take an initialization
subdirectory (by default ending ".init") and copy it over to a run
directory (by default ending ".dir"), doing a C<chdir> into the run
directory, and then parsing a C<Slay::Makefile> to define and run the
tests.  A reasonable way to accomplish this is to have the
C<Slay::Makefile> create a file with extension ".ok" that is empty if
the test passes; frequently this file can be the output of a diff
between the test's output and an expect file.  The C<Slay::Makefile>
can be in a parent directory so it can be shared by more than one
suite of tests (.t file).  A shared C<Slay::Makefile> can use the
include mechanism to bring in a local C<Slay::Makefile> files in the
run directory.  You can even use this methodology for developing
families of suites of tests, etc.

=head1 ROUTINES

=over

=item C<do_tests($makefile[, @tests] [, \%options ])>

Runs a series of tests using C<$makefile> as the C<Slay::Makefile>
input.  If C<@tests> are specified, it contains the list of tests,
each of which is a target that is built in order; otherwise the
dependencies of the C<test> target will be built as the list of tests.
The following options are recognized:

=over

=item init

The extension for the initialization directory.  Default is '.init'.

=item opts

A hash reference to be passed to Slay::Makefile::new as its options list.

=item pretest

The name of the target to be built prior to running tests to set
everything up.  Default is 'pretest'.

=item run

The extension for the run directory.  Default is '.run'.

=item skip

The name for perl scripts to run to check whether all tests should be
skipped.  The name is also used as an extension for a test's base name
to see if an individual tests should be skipped.

=item test

The name of the target whose dependencies gives the list of tests.
Default is 'test'.

=back

=back

=head1 PROCESSING

Processing proceeds by the following steps:

=over

=item 1.

Search for an initialization directory with the same base name as the
.t file invoking C<do_tests> and extension equal to the C<init>
option.  Croaks if there is no such directory.  For example, if the file
invoking c<do_tests> is C<cmdline.t> and the default initialization
extension is used, it looks for directory C<cmdline.init>.

=item 2.

Copy the initialization directory to a run directory and C<cd> into that
directory.

=item 3.

Check for a script with the name of the C<skip> option.  If it exists,
execute it.  If it returns a non-zero exit code, skip all the tests.
The text this script prints becomes the reason for skipping the tests.

=item 4.

Use C<Slay::Makefile> to parse the C<$makefile> file.  Note that the
working directory is the run directory when this file is processed.

=item 5.

Do a C<Slay::Makefile::make> of the C<pretest> target, if it exists.
The name of the C<pretest> target is 'pretest' unless specified in the
options.

=item 6.

If C<@tests> is empty, create a list of tests to execute by getting
the dependencies of the C<test> target.  The name of the C<test>
target is 'test' unless specified in the options.

=item 7.

For each test C<t>,

=over

=item a.

Check for a script with the same base name as C<t> and the extension
C<.> and the name of the C<skip> option..  For example, if the default
value of the C<skip> option is used, then a test C<algebra.ok> would
use a script called C<algebra.skip.pl>.  If the script exists, execute
it and skip the test if it returns a non-zero exit code.  The text
this script prints becomes the reason for skipping the test.

=item b.

Run C<Slay::Makefile::make> for target C<t>.

=item c.

If no file C<t> was generated, report a failed test as failing to
build the file.  If C<t> was generated, then it should be empty for a
passing test.  Any text in the file is returned as the reason for the
tests's failure.

=back

=back

=cut

sub do_tests {
    my ($makefile, @tests) = @_;

    # Get the options
    my $options = pop @tests if ref($tests[-1]) eq 'HASH';
    $options = {} unless $options;
    $options->{init}    ||= '.init';
    $options->{opts}    ||= { strict => 1 } ;
    $options->{pretest} ||= 'pretest';
    $options->{run}     ||= '.run';
    $options->{skip}    ||= 'skip.pl';
    $options->{test}    ||= 'test';

    my $base = $FindBin::RealBin;
    my ($myname) =  $FindBin::RealScript =~ /(.*)\.t$/;
    chdir $base;
    my $init = "$myname$options->{init}";
    croak "Error: No initialization directory '$init' for this test\n"
	unless -d $init;
    my $top = `pwd`;
    chomp $top;
    $top =~ s!/[^/]*$!! while $top && ! -d "$top/blib/lib";
    my $use_lib = $top ? "-I$top/blib/lib" : '';

    # First create the run subdirectory for doing testing
    my $run = "$myname$options->{run}";

    rmtree $run if -d $run;
    dircopy $init, $run;

    chdir $run;

    # Check to see if we need to skip all tests
    my $skip = $options->{skip};
    if (-f $skip) {
	chomp (my $error = `$^X $use_lib $skip 2>&1`);
	plan(skip_all => "$error") if $?;
    }

    my $sm = Slay::Makefile->new($options->{opts});

    # Have carp within Slay::Makefile trust Slay::Makefile::Gress
    local @Slay::Makefile::CARP_NOT;
    push @Slay::Makefile::CARP_NOT, 'Slay::Makefile::Gress';
    my $errs = $sm->parse($makefile);

    # Run the pretest target, if any
    eval { $sm->make($options->{pretest}); };

    # Get list of targets
    if (! @tests) {
	$sm->maker->check_targets($options->{test});
	my ($rule, $deps, $matches) =
	    $sm->maker->get_rule_info($options->{test});
	@tests = defined $rule && $deps ? @$deps : () ;
    }
    plan tests => 0+@tests;
  TEST:
    foreach my $test (@tests) {
	(my $base_test = $test) =~ s/\. [^\.]+ \z//x;
	if (-f "$base_test.$skip") {
	    # Check whether we need to skip this file
	    chomp (my $error = `$^X $use_lib $base_test.$skip 2>&1`);
	  SKIP:
	    {
		skip($error, 1) if $?;
	    }
	    next TEST if $?
	}
	$sm->make($test);
	my $ok = -r $test ? `cat $test` : "Failed to build $test";
	is ($ok, '', $test);
    }
}

1;
