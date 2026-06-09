use strict;
use warnings;
use Test::Most;

# Basic load and sanity tests.
# Note: use_ok loads the module at runtime (past CHECK), which triggers
# "Too late to run CHECK block" -- that is expected and harmless here
# because this file does not exercise the declarative import form.
use_ok 'Sub::Protected';

ok defined(&Sub::Protected::_wrap),         '_wrap is defined';
ok defined(&Sub::Protected::_check_access), '_check_access is defined';

# ------------------------------------------------------------------
# Identifier validation in import()
# ------------------------------------------------------------------

throws_ok { Sub::Protected->import('123bad') }
	qr/is not a valid Perl identifier/,
	'import rejects names starting with a digit';

throws_ok { Sub::Protected->import('has-hyphen') }
	qr/is not a valid Perl identifier/,
	'import rejects names containing a hyphen';

throws_ok { Sub::Protected->import(q{}) }
	qr/is not a valid Perl identifier/,
	'import rejects empty string';

lives_ok { Sub::Protected->import() }
	'import with no args lives';

# ------------------------------------------------------------------
# Private-method guard on _wrap
# ------------------------------------------------------------------
# _wrap must croak when called from outside Sub::Protected,
# unless the bypass is active.

{
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# Calling _wrap from main:: (this test file) must be blocked.
	throws_ok {
		Sub::Protected::_wrap('Some::Pkg', 'some_sub', sub { 1 });
	} qr/_wrap\(\) is a private method of Sub::Protected/,
		'_wrap is blocked from outside Sub::Protected';
}

{
	# Calling _wrap with BYPASS=1 must succeed (returns a coderef).
	local $Sub::Protected::BYPASS = 1;
	my $wrapped;
	lives_ok {
		$wrapped = Sub::Protected::_wrap('Some::Pkg', 'some_sub', sub { 42 });
	} '_wrap is allowed with BYPASS=1';
	ok ref($wrapped) eq 'CODE', '_wrap returns a CODE ref when bypassed';
}

done_testing;
