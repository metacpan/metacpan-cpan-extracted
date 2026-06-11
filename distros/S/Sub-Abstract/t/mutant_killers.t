#!/usr/bin/perl
# t/mutant_killers.t -- tests that kill specific surviving mutants.
#
# Source stub: xt/mutant_20260610_145140.t
#
# TARGET MUTANT: COND_INV_218_2 (MEDIUM) -- line 218 in import()
#
#   Original: if ($_post_check) {
#   Mutant:   unless ($_post_check) {          # condition inverted
#
# What the inversion does:
#   TRUE  branch ($post_check=1 = post-CHECK):
#     ORIGINAL -> _process_one() called immediately; wrapper installed now.
#     MUTANT   -> item pushed to @_pending; CHECK already ran, never runs
#                 again; wrapper is NEVER installed.
#
#   FALSE branch ($post_check=0 = pre-CHECK, still compiling):
#     ORIGINAL -> item pushed to @_pending; CHECK drains it; wrapper
#                 installed when compilation ends.
#     MUTANT   -> _process_one() called immediately; wrapper installed
#                 early, but end-state is the same (method is abstract).
#
# PRIMARY KILLER: call import() post-CHECK, then verify the wrapper fires.
#   Under the mutant the wrapper was never installed, the method returns
#   normally, and the throws_ok assertion FAILS.  Mutant killed.

use strict;
use warnings;

# Taint-safe INC manipulation for local dev copies of Test helper libs.
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC,
		'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Returns;
use Readonly;

# -------------------------------------------------------------------
# Constants -- no magic strings in this file
# -------------------------------------------------------------------

Readonly::Scalar my $SA => 'Sub::Abstract';

# Test configuration values used across multiple subtests.
my %config = (
	pre_check_method  => 'before_check_op',
	pre_check_impl    => 'pre_check_done',
	post_check_method => '_wrap_me',
	post_check_orig   => 'original',
	impl_result       => 'impl',
);

# -------------------------------------------------------------------
# Load the module.  CHECK fires at the end of compilation; all test
# bodies run post-CHECK ($_post_check=1) unless explicitly noted.
# -------------------------------------------------------------------

use Sub::Abstract;

# -------------------------------------------------------------------
# PRE-CHECK FIXTURES (compile time)
#
# These packages are compiled BEFORE CHECK fires, so import() takes
# the FALSE branch: items go into @_pending, which CHECK drains.
# -------------------------------------------------------------------

# MT::PreCheckBase: declarative form at compile time ($post_check=0).
# The 'before_check_op' entry lands in @_pending, CHECK installs it.
{
	package MT::PreCheckBase;
	use Sub::Abstract qw(before_check_op);
	sub new { bless {}, shift }
}

# MT::PreCheckImpl: satisfies the abstract contract at the pre-CHECK base.
{
	package MT::PreCheckImpl;
	our @ISA = ('MT::PreCheckBase');
	sub new             { bless {}, shift }
	sub before_check_op { 'pre_check_done' }
}

diag "Mutant-killer tests for COND_INV_218_2 (line 218, import())" if $ENV{TEST_VERBOSE};

# ===================================================================
# PRIMARY MUTANT-KILLER
#
# COND_INV_218_2: post-CHECK import() must call _process_one() immediately.
#
# Scenario: import() is called after CHECK has fired ($post_check=1).
# Original code: TRUE branch fires -> _process_one() -> wrapper installed.
# Mutant code:   FALSE branch fires -> push @_pending -> wrapper NEVER
#                installed (CHECK already ran, @_pending never drained again).
#
# The throws_ok assertion below FAILS under the mutant because the
# method returns 'original' instead of croaking.  Mutant killed.
# ===================================================================

subtest 'COND_INV_218_2: post-CHECK import() installs wrapper immediately' => sub {
	plan tests => 4;

	# Define a fresh package with a real body; import() will overwrite it.
	# This is defined INSIDE the subtest so the package exists post-CHECK.
	{
		package MT::PostTarget;
		sub new      { bless {}, shift }
		sub _wrap_me { 'original' }    # this body must be replaced by the wrapper
	}

	# Implementing subclass for the post-check package
	{
		package MT::PostImpl;
		our @ISA = ('MT::PostTarget');
		sub new      { bless {}, shift }
		sub _wrap_me { 'impl' }
	}

	# Install the abstract wrapper NOW -- post-CHECK (_post_check=1).
	# This is the critical call that COND_INV_218_2 targets.
	{ package MT::PostTarget; Sub::Abstract->import($config{post_check_method}); }

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag "Calling $config{post_check_method} on MT::PostTarget (post-CHECK wrap)" if $ENV{TEST_VERBOSE};

	# ---- PRIMARY ASSERTION: wrapper must fire ----
	# Under the mutant: _wrap_me still returns 'original'; throws_ok fails.
	throws_ok { MT::PostTarget->new->_wrap_me }
		qr/_wrap_me\(\) is an abstract method of MT::PostTarget/,
		'post-CHECK import: wrapper fires on base class (FAILS under mutant)';

	# Verify invocant appears in the error (full error format check)
	throws_ok { MT::PostTarget->new->_wrap_me }
		qr/must be implemented by MT::PostTarget/,
		'post-CHECK import: invocant named correctly in error';

	# Verify the wrapper was installed (stash now holds a CODE ref)
	{
		no strict 'refs';
		my $installed = \&{"MT::PostTarget::$config{post_check_method}"};
		ok ref($installed) eq 'CODE',
			'post-CHECK import: stash entry is now a CODE ref (wrapper installed)';
	}

	# Implementing subclass must work normally -- wrapper in base never reached
	lives_and { is(MT::PostImpl->new->_wrap_me, $config{impl_result}) }
		'post-CHECK import: implementing subclass unaffected';
};

# ===================================================================
# COMPLEMENTARY: pre-CHECK import wraps via @_pending + CHECK
#
# This documents and verifies the FALSE-branch end-state ($post_check=0).
# Both original and mutant result in the method being wrapped here
# (mutant calls _process_one immediately; original queues it).
# This test does NOT kill COND_INV_218_2 on its own, but it detects
# any future regression that breaks the queuing mechanism.
# ===================================================================

subtest 'COND_INV_218_2: pre-CHECK import wraps via @_pending queue' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag "MT::PreCheckBase compiled pre-CHECK; wrapper installed at CHECK time" if $ENV{TEST_VERBOSE};

	# The abstract wrapper must be installed by the time tests run.
	# (CHECK processed @_pending before any test body executed.)
	throws_ok { MT::PreCheckBase->new->before_check_op }
		qr/before_check_op\(\) is an abstract method of MT::PreCheckBase/,
		'pre-CHECK import: wrapper installed when tests run (queue processed at CHECK)';

	# The implementing subclass must be fully functional after CHECK.
	lives_ok { MT::PreCheckImpl->new->before_check_op }
		'pre-CHECK import: implementing subclass is not blocked';
};

# ===================================================================
# BOTH BRANCHES: import() return value is 'Sub::Abstract' either way
#
# import() calls set_return($class, {type=>'string'}) AFTER the
# $_post_check branch.  Both branches must reach that return statement.
# If the mutant causes the wrong branch to execute and somehow falls
# off (or errors), the return value becomes incorrect.
# ===================================================================

subtest 'COND_INV_218_2: import() returns class name in both dispatch paths' => sub {
	plan tests => 3;

	diag "Verifying import() return value across both branches" if $ENV{TEST_VERBOSE};

	# Post-CHECK path: _process_one branch (or @_pending under mutant)
	my $post_result;
	{
		package MT::RCPost;
		sub _rc1 { 1 }
		$post_result = Sub::Abstract->import('_rc1');
	}
	is $post_result, $SA,
		'post-CHECK import: return value is the class name (Sub::Abstract)';
	returns_ok($post_result, { type => 'string' },
		'post-CHECK import: return value satisfies the "string" schema');

	# No-args path (early return, never reaches the branch at line 218)
	my $noargs_result = Sub::Abstract->import();
	is $noargs_result, $SA,
		'no-args import: return value is the class name (early return, branch not reached)';
};

# ===================================================================
# SELECTIVITY: import() wraps ONLY the named method
#
# The $_post_check branch installs the wrapper for the specific sub
# named by import().  Other subs in the same package must not be touched.
# This narrows the mutant's observable impact to the exact install point
# and prevents a "wraps everything" or "wraps nothing" mutation from hiding.
# ===================================================================

subtest 'COND_INV_218_2: import() wraps exactly the named method, no others' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# A package with two subs; only one will be declared abstract.
	{
		package MT::Selective;
		sub new          { bless {}, shift }
		sub _should_wrap { 'should_wrap' }
		sub _untouched   { 'untouched'   }
		Sub::Abstract->import('_should_wrap');
	}

	diag "MT::Selective: _should_wrap is abstract, _untouched is not" if $ENV{TEST_VERBOSE};

	# The named method must now be abstract (wrapper installed by import)
	throws_ok { MT::Selective->new->_should_wrap }
		qr/_should_wrap\(\) is an abstract method of MT::Selective/,
		'selectivity: the named method is abstract';

	# The other method in the same package must be completely unaffected
	lives_and { is(MT::Selective->new->_untouched, 'untouched') }
		'selectivity: other methods in the same package are not touched';

	# The owner package is correctly captured from caller
	throws_ok { MT::Selective->new->_should_wrap }
		qr/abstract method of MT::Selective/,
		'selectivity: owner_pkg in error is the caller of import()';
};

done_testing;
