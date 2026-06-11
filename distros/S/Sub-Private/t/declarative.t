use strict;
use warnings;
use Test::Most;

# Tests for the declarative import form: use Sub::Private qw(_helper).
# Declarative form only works in enforce mode; namespace mode croaks.

# Must be set via BEGIN so that 'use Sub::Private qw(...)' lines below
# don't croak during compilation (they call import() at compile time).
BEGIN { $Sub::Private::config{mode} = 'enforce' }

use Sub::Private;

local $ENV{HARNESS_ACTIVE}  = 0;
local $Sub::Private::BYPASS = 0;

# ---- Test 1: declarative form wraps sub in enforce mode ----

{
	package DecFoo;
	use Sub::Private qw(_private);

	sub new      { bless {}, shift }
	sub _private { 'private value' }
	sub public   { (shift)->_private }
}

{
	package DecExternal;
	sub probe { DecFoo->new->_private }
}

my $obj = DecFoo->new;

throws_ok { DecExternal::probe() }
	qr/\Q_private() is a private subroutine of DecFoo and cannot be called from DecExternal\E/,
	'declarative form: external caller blocked';

lives_and { is $obj->public, 'private value' }
	'declarative form: owner package can call wrapped sub';

# ---- Test 2: multiple sub names in one import ----

{
	package DecMulti;
	use Sub::Private qw(_a _b);

	sub new { bless {}, shift }
	sub _a  { 'a' }
	sub _b  { 'b' }
	sub run { my $s = shift; $s->_a . $s->_b }
}

my $got;
lives_ok { $got = DecMulti->new->run } 'declarative form: owner can call multiple wrapped subs';
is $got, 'ab', 'declarative form: multiple subs wrapped in one import';

throws_ok { DecMulti::_a(DecMulti->new) }
	qr/private subroutine/,
	'declarative form: first of multiple subs still private from outside';

# ---- Test 3: invalid identifier croaks ----

throws_ok { Sub::Private->import('123bad') }
	qr/is not a valid Perl identifier/,
	'declarative form: identifier starting with digit is rejected';

throws_ok { Sub::Private->import('has-hyphen') }
	qr/is not a valid Perl identifier/,
	'declarative form: identifier with hyphen is rejected';

# ---- Test 4: import(undef) croaks with identifier message (not downstream error) ----

throws_ok { Sub::Private->import(undef) }
	qr/is not a valid Perl identifier/,
	'import(undef): croaks with "not a valid Perl identifier", not a downstream error';

throws_ok { Sub::Private->import({}) }
	qr/is not a valid Perl identifier/,
	'import({}): hashref sub name croaks with "not a valid Perl identifier"';

# ---- Test 5: declarative form with namespace mode croaks ----

{
	local $Sub::Private::config{mode} = 'namespace';

	throws_ok { Sub::Private->import('_any') }
		qr/declarative form requires mode => 'enforce'/,
		'declarative form with mode=namespace croaks with descriptive message';
}

# ---- Test 6: non-existent sub croaks at wrap time ----

{
	local $Sub::Private::BYPASS = 1;

	throws_ok {
		package DecNoSub;
		Sub::Private->import('_no_such_sub_xyz');
	} qr/_no_such_sub_xyz is not defined/,
		'import(): croaks when the named sub does not exist';
}

done_testing;
