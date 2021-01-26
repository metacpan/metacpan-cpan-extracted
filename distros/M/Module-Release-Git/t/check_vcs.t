#!/usr/bin/perl
use strict;
use vars qw(
	$output
	$newfile_output $changedfile_output
	$untrackedfile_output $combined_output
	);

use Test::More 'no_plan';

my $class  = 'Module::Release::Git';
my $method = 'check_vcs';

use_ok( $class );
can_ok( $class, $method );

# are we where we think we're starting?
can_ok( $class, 'run' );
is( $class->run, $output );

# we're testing, so turn off output (kludge)
{
no warnings 'redefine';
*Module::Release::Git::_print = sub { 1 };
*Module::Release::Git::_die   = sub { my $self = shift; die @_ };
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test when there is nothing left to commit (using the starting $output)
foreach my $try (qw(fine_output clean_output_git_2x)) {
	no strict 'refs';
	local $Module::Release::Git::run_output = ${ "Module::Release::Git::$try" };

	my $rc = eval { $class->$method() };
	my $at = $@;
	diag( "EVAL error: $at" ) if $at;

	ok( ! $at, "(Nothing left to commit) \$@ undef (good)" );
	ok( $rc, "(Nothing left to commit) returns true (good)" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test when there is a new file
foreach my $try (qw(newfile_output changedfile_output
	untrackedfile_output combined_output ) )
	{
	no strict 'refs';
	local $Module::Release::Git::run_output =
		${ "Module::Release::Git::$try" };

	#print STDERR "try is $Module::Release::Git::run_output\n";

	my $rc = eval { $class->$method() };
	my $at = $@;

	#print STDERR "At is $@\n";

	ok( defined $at, "(Dirty working dir) \$@ defined (good)" );
	ok( ! $rc, "(Dirty working dir) returns true (good)" );
	like( $at, qr/not up-to-date/, "Reports that Git is not up-to-date" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
=pod

To test these functions, I want to give them some sample git
output and ensure they do what I want them to do. Instead of
running git, I override the run() method to return whatever
is in the global variable $output. I can change that during
the test run to try different things.

=cut

BEGIN {
package Module::Release::Git;
use vars qw( $run_output $fine_output $clean_output_git_2x
	$newfile_output $changedfile_output
	$untrackedfile_output $combined_output
	);


# https://github.com/briandfoy/module-release-git/pull/2
# This used to be sample output, but Corion used more
# sophisticated steps that don't require output parsing
$fine_output = <<"HERE";
HERE

$clean_output_git_2x = <<"HERE";
HERE

no warnings 'redefine';
package Module::Release::Git; # load before redefine
sub run { $run_output }

$newfile_output = <<"HERE";
# On branch master
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#       new file:   README
HERE

$changedfile_output = <<"HERE";
# On branch master
# Changed but not updated:
#   (use "git add <file>..." to update what will be committed)
#
#       modified:   .gitignore
HERE

$untrackedfile_output = <<"HERE";
# On branch master
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#
#       Changes
#       LICENSE
#       MANIFEST.SKIP
HERE

$combined_output = <<"HERE";
# On branch master
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#       new file:   README
#
# Changed but not updated:
#   (use "git add <file>..." to update what will be committed)
#
#       modified:   .gitignore
#
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#
#       Changes
#       LICENSE
#       MANIFEST.SKIP
#       Makefile.PL
#       examples/
#       lib/
#       t/
HERE

}
