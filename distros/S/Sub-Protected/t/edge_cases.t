use strict;
use warnings;
use Test::Most;
use Sub::Protected;

# Tests 12, 13, 16-18: both forms identical, deep chains, anonymous subs,
# cross-protected calls, independent enforcement.

local $ENV{HARNESS_ACTIVE}    = 0;
local $Sub::Protected::BYPASS = 0;

# ---- Test 12: attribute form and declarative form produce identical behaviour ----

{
    package AttrPkg;
    use Sub::Protected;
    sub new  { bless {}, shift }
    sub _sec :Protected { 'attr-sec' }
    sub pub  { (shift)->_sec }
}

{
    package DeclPkg;
    use Sub::Protected qw(_sec);
    sub new  { bless {}, shift }
    sub _sec { 'decl-sec' }
    sub pub  { (shift)->_sec }
}

{
    package Outsider;
    sub probe_attr { AttrPkg->new->_sec }
    sub probe_decl { DeclPkg->new->_sec }
}

lives_ok { AttrPkg->new->pub }   'attr form: owner allowed';
lives_ok { DeclPkg->new->pub }   'decl form: owner allowed';
throws_ok { Outsider::probe_attr() } qr/protected method/, 'attr form: outsider blocked';
throws_ok { Outsider::probe_decl() } qr/protected method/, 'decl form: outsider blocked';

# ---- Test 13: deep call chain — blocked at first non-owner frame ----

{
    package Deep;
    use Sub::Protected;
    sub new      { bless {}, shift }
    sub _hidden  :Protected { 'deep' }
    sub entry    { (shift)->_hidden }    # owner → allowed
}

{
    package Middle;
    sub via { Deep->new->_hidden }   # intermediate non-owner → blocked
}

{
    package Outer;
    sub call_via { Middle::via() }   # further caller → the walk still finds Middle first
}

throws_ok { Middle::via() }      qr/protected method/, 'deep chain: blocked at Middle';
throws_ok { Outer::call_via() }  qr/protected method/, 'deep chain: still blocked when called through Outer';
lives_ok  { Deep->new->entry }   'deep chain: direct owner call allowed';

# ---- Test 16: anonymous sub as caller is blocked ----

my $anon = sub { Deep->new->_hidden };
throws_ok { $anon->() } qr/protected method/,
    'anonymous sub caller is blocked (compiled in main)';

# ---- Test 17: protected sub calling another protected sub in the same package ----

{
    package Sibling;
    use Sub::Protected;
    sub new   { bless {}, shift }
    sub _one  :Protected { 'one' }
    sub _two  :Protected { my $self = shift; 'two+' . $self->_one }
    sub run   { (shift)->_two }
}

my $got;
lives_ok { $got = Sibling->new->run } 'sibling protected call lives';
is $got, 'two+one', 'protected sub can call sibling protected sub in the same package';

# ---- Test 18: two independently wrapped subs enforce independently ----

{
    package Twin;
    use Sub::Protected;
    sub new  { bless {}, shift }
    sub _p   :Protected { 'p' }
    sub _q   :Protected { 'q' }
    sub get_p { (shift)->_p }
    sub get_q { (shift)->_q }
}

lives_ok { Twin->new->get_p } 'Twin: owner can call _p';
lives_ok { Twin->new->get_q } 'Twin: owner can call _q';

throws_ok { Twin::_p(Twin->new) } qr/protected method/, 'Twin: _p blocked from outside';
throws_ok { Twin::_q(Twin->new) } qr/protected method/, 'Twin: _q blocked from outside independently';

# ---- import() with undef or reference sub name -- must reject cleanly ----
# Previously undef slipped past validate_strict and reached _process_one,
# producing a misleading "is not defined" message instead of the documented one.

throws_ok { Sub::Protected->import(undef) }
	qr/is not a valid Perl identifier/,
	'import(undef): croaks with "not a valid Perl identifier", not a downstream error';

throws_ok { Sub::Protected->import({}) }
	qr/is not a valid Perl identifier/,
	'import({}): hashref sub name croaks with "not a valid Perl identifier"';

# ---- Protected sub returning false values -- they must propagate intact ----

{
	package FalseReturn;
	use Sub::Protected;
	sub new        { bless {}, shift }
	sub _undef     :Protected { return undef }
	sub _zero      :Protected { return 0 }
	sub _empty     :Protected { return q{} }
	sub get_undef  { (shift)->_undef }
	sub get_zero   { (shift)->_zero }
	sub get_empty  { (shift)->_empty }
}

{
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	ok(!defined(FalseReturn->new->get_undef), 'edge: protected sub returning undef: propagates');
	is(FalseReturn->new->get_zero,  0,   'edge: protected sub returning 0: propagates');
	is(FalseReturn->new->get_empty, q{}, 'edge: protected sub returning "": propagates');
}

# ---- goto &$code forwards args -- positional args reach the protected body ----

{
	package ArgPass;
	use Sub::Protected;
	sub new    { bless {}, shift }
	sub _sum   :Protected { my (undef, $a, $b) = @_; $a + $b }
	sub run    { my $s = shift; $s->_sum(@_) }
}

{
	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	is(ArgPass->new->run(10, 20), 30, 'edge: goto &$code forwards positional args (10+20=30)');
}

done_testing;
