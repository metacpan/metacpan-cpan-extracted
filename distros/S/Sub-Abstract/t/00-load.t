use strict;
use warnings;
use Test::Most;

# Basic load and sanity tests.
# Note: use_ok loads the module at runtime (past CHECK), which triggers
# "Too late to run CHECK block" -- that is expected and harmless here
# because this file does not exercise the declarative import form.
diag('Ignore the "Too late to run CHECK block" message');
use_ok 'Sub::Abstract';

ok defined(&Sub::Abstract::_wrap),         '_wrap is defined';
ok defined(&Sub::Abstract::_process_one),  '_process_one is defined';

# ------------------------------------------------------------------
# Identifier validation in import()
# ------------------------------------------------------------------

throws_ok { Sub::Abstract->import('123bad') }
	qr/is not a valid Perl identifier/,
	'import rejects names starting with a digit';

throws_ok { Sub::Abstract->import('has-hyphen') }
	qr/is not a valid Perl identifier/,
	'import rejects names containing a hyphen';

throws_ok { Sub::Abstract->import(q{}) }
	qr/is not a valid Perl identifier/,
	'import rejects empty string';

throws_ok { Sub::Abstract->import(undef) }
	qr/is not a valid Perl identifier/,
	'import rejects undef';

throws_ok { Sub::Abstract->import({}) }
	qr/is not a valid Perl identifier/,
	'import rejects a reference';

lives_ok { Sub::Abstract->import() }
	'import with no args lives';

# ------------------------------------------------------------------
# Private-method guard on _wrap
# ------------------------------------------------------------------
# _wrap must croak when called from outside Sub::Abstract,
# unless the bypass is active.

{
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok {
		Sub::Abstract::_wrap('Some::Pkg', 'some_sub');
	} qr/_wrap\(\) is a private method of Sub::Abstract/,
		'_wrap is blocked from outside Sub::Abstract';
}

{
	local $Sub::Abstract::BYPASS = 1;
	my $wrapped;
	lives_ok {
		$wrapped = Sub::Abstract::_wrap('Some::Pkg', 'some_sub');
	} '_wrap is allowed with BYPASS=1';
	ok ref($wrapped) eq 'CODE', '_wrap returns a CODE ref when bypassed';
}

done_testing();
