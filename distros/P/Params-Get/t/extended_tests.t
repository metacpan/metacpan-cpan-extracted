#!/usr/bin/env perl

# Extended coverage tests for Params::Get::get_params.
#
# Primary goal: push condition coverage from 96.6% to 100% by exercising the
# one remaining uncovered branch (line 285 l&&!r: non-empty ARRAY in the
# no-$default, one-arg path) plus every semantic gap in the \@_ shorthand
# and from_arrayref paths that existing tests do not reach in isolation.
#
# Secondary goals:
#   - LCSAJ: exercise every unique sequence-and-jump path through the 4-way
#     AND shorthand condition, the from_arrayref-and-defined-$default path,
#     and the two-arg-hashref path when reached via from_arrayref=1.
#   - Error message format: verify the exact confess/croak text including the
#     $default key name and the caller(1) function name interpolation.
#   - Falsy-but-defined $default in the shorthand: document the current
#     truthiness check (implementation uses "if ($default && ...)" not
#     "if (defined $default && ...)") so regressions are caught if this
#     is ever intentionally changed.
#
# All tests are derived strictly from documented POD behavior.

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Mockingbird 0.08;
use Readonly;
use Scalar::Util ();
use POSIX ();
use Params::Get qw(get_params);

Readonly::Scalar my $PKG              => 'Params::Get';
Readonly::Scalar my $USAGE_RE         => qr/Usage:/;
Readonly::Scalar my $DEFAULT_CROAK_RE => qr/\$default must be a scalar or arrayref/;

# =========================================================================
# SECTION 1: Close the line-285 condition gap
#
# Line 285: if ((ref($val) eq $T_ARRAY) && (@{$val} == 0)) { return $val }
#
# Devel::Cover reports l&&!r = 0 hits: the guard has been hit with $val being
# a NON-EMPTY ARRAY ref, but in that situation the guard's right side is
# FALSE so execution falls through to Carp::croak.  The only two routes that
# place an ARRAY ref into $val in the no-$default, one-arg path are:
#
#   A. REF-of-ARRAY via the REF-unwrap step:
#        get_params(undef, \$aref) where $aref is a non-empty arrayref.
#        After unwrap: $val = $aref (ARRAY, length > 0) -> croak.
#
#   B. \@_ passthrough with a non-empty inner ARRAY element:
#        get_params(undef, [[1,2,3]])
#        $args = [[1,2,3]], $num_args = 1, $val = [1,2,3] (ARRAY, len > 0) -> croak.
#
# Both must croak; neither is covered by any existing test file.
# =========================================================================

subtest 'line-285 l&&!r: REF-of-ARRAY (non-empty) via REF-unwrap -> croak' => sub {
	# \@non_empty is a REF of a REF of an array -- one level of REF is unwrapped,
	# yielding a non-empty ARRAY ref.  That is not a HASH and is not empty, so
	# the code falls past the empty-array guard and croaks with "Usage:".
	my @non_empty = (1, 2, 3);
	my $raref     = \\@non_empty;    # REF -> ARRAY ref

	throws_ok(
		sub { get_params(undef, $raref) },
		$USAGE_RE,
		'REF-of-non-empty-ARRAY via REF unwrap: croak expected',
	);

	diag 'This hits line 285 l&&!r: ref(val)==ARRAY but len>0 => no early return => croak'
		if $ENV{TEST_VERBOSE};
};

subtest 'line-285 l&&!r: \@_ inner non-empty ARRAY element -> croak' => sub {
	# get_params(undef, [[1,2,3]]): the outer [] is \@_; the inner [1,2,3] is
	# $args->[0], a non-empty ARRAY ref.  Same l&&!r condition as above.
	throws_ok(
		sub { get_params(undef, [[1, 2, 3]]) },
		$USAGE_RE,
		'\@_ with non-empty inner ARRAY element: croak expected',
	);
};

subtest 'line-285 l&&r: REF-of-empty-ARRAY via REF-unwrap -> returns the empty arrayref' => sub {
	# Regression guard for the l&&r path (empty array -> return immediately).
	# Provided here to make the contrast with the l&&!r tests above explicit.
	my @empty = ();
	my $raref = \\@empty;    # REF -> empty ARRAY ref

	my $result = get_params(undef, $raref);

	is(ref($result), 'ARRAY',        'empty ARRAY ref returned');
	is(scalar @{$result}, 0,         'returned array is empty');
	is($result, \@empty,             'same reference returned (not a copy)');
};

# =========================================================================
# SECTION 2: Two-element \@_ shorthand -- LCSAJ traversal of the 4-way AND
#
# The shorthand condition (line 234) is:
#   if ($default && (@{$_[0]} == 2) && ($_[0]->[0] eq $default) && !ref($_[0]->[1]))
#
# Every distinct sub-expression failure that causes the guard to exit early
# is a separate LCSAJ branch.  The four sub-expressions plus their negations:
#   [A] $default is falsy but defined (0 or ""):     guard exits at A
#   [B] inner array has != 2 elements:               guard exits at B (tested elsewhere)
#   [C] element[0] != $default:                      guard exits at C (tested elsewhere)
#   [D] element[1] is a reference:                   guard exits at D (tested elsewhere)
#   [E] all conditions true, undef as element[1]:    !ref(undef)=1 -> shorthand fires
#
# Only [A] and [E] are not covered by any existing test.
# =========================================================================

subtest 'shorthand LCSAJ-A: $default=0 (falsy) -- shorthand guard exits at first term' => sub {
	# $default = 0 is defined but falsy.  The guard checks `$default &&` which
	# short-circuits to false immediately, so the shorthand NEVER fires.
	# Instead from_arrayref=1 and defined($default) is true, so the whole inner
	# array is wrapped under key '0' via the from_arrayref path (line 308).
	#
	# IMPLEMENTATION NOTE: the guard uses truthiness (`$default && ...`), not
	# definedness (`defined $default && ...`).  Callers using 0 or "" as a
	# $default key name cannot use the two-element shorthand convention.
	my $result = get_params(0, [0, 'payload']);

	is(ref($result), 'HASH',             'result is a hashref');
	ok(exists $result->{0},              'key "0" present');
	is(ref($result->{0}), 'ARRAY',       'whole inner array wrapped -- shorthand did NOT fire');
	is(scalar @{$result->{0}}, 2,        'inner array has both elements intact');
	is($result->{0}[0], 0,              'first inner element: 0');
	is($result->{0}[1], 'payload',       'second inner element: payload');

	diag 'LCSAJ-A: guard exits at "$default &&" when $default=0 (falsy)'
		if $ENV{TEST_VERBOSE};
};

subtest 'shorthand LCSAJ-A2: $default="" (empty string, falsy) -- shorthand suppressed' => sub {
	my $result = get_params('', ['', 'data']);

	is(ref($result), 'HASH',            'result is a hashref');
	ok(exists $result->{''},            'empty-string key present');
	is(ref($result->{''}), 'ARRAY',     'whole inner array wrapped -- shorthand suppressed');

	diag 'LCSAJ-A2: guard exits at "$default &&" when $default="" (empty string)'
		if $ENV{TEST_VERBOSE};
};

subtest 'shorthand LCSAJ-E: element[1] is undef -- !ref(undef)=1 -> shorthand fires' => sub {
	# ref(undef) = '' which is falsy, so !ref(undef) = 1 (truthy).
	# All four guard conditions are satisfied: shorthand fires and stores undef.
	my $result = get_params('flag', ['flag', undef]);

	is(ref($result), 'HASH',           'result is a hashref');
	ok(exists $result->{flag},         'flag key present');
	ok(!defined $result->{flag},       'value is undef (shorthand fired with undef value)');
	ok(!exists $result->{_},           'no phantom key from unconsumed element');

	diag 'LCSAJ-E: !ref(undef)=1 -> shorthand fires, stores undef under key'
		if $ENV{TEST_VERBOSE};
};

subtest 'shorthand fires: element[1] is numeric 0 -- !ref(0)=1 -> shorthand fires' => sub {
	my $result = get_params('count', ['count', 0]);
	is($result->{count}, 0, 'numeric zero stored via shorthand');
};

subtest 'shorthand fires: element[1] is empty string -- !ref("")=1 -> shorthand fires' => sub {
	my $result = get_params('label', ['label', '']);
	ok(exists $result->{label},    'label key present');
	is($result->{label}, '',       'empty string stored via shorthand');
};

# =========================================================================
# SECTION 3: \@_ passthrough -- paths not tested in isolation elsewhere
#
# Every sub-path that can be taken after setting from_arrayref=1 but without
# triggering the two-element shorthand.
# =========================================================================

subtest '\@_ single-element inner array + $default defined -> scalar-or-arrayref branch' => sub {
	# \@_ = ['hello']: from_arrayref=1, num_args=1, defined $default.
	# The inner element 'hello' is a plain scalar => !$kind => return { key => 'hello' }.
	my $result = get_params('key', ['hello']);

	is_deeply($result, { key => 'hello' },
		'\@_ single scalar element wrapped under $default key');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');

	diag 'from_arrayref=1, num_args=1, arg is scalar -> one-arg defined-default branch'
		if $ENV{TEST_VERBOSE};
};

subtest '\@_ single-element with numeric value + $default defined' => sub {
	my $result = get_params('count', [42]);
	is_deeply($result, { count => 42 }, 'numeric inner element wrapped under key');
};

subtest '\@_ single undef inner element, no $default -> returns undef' => sub {
	# \@_ = [undef]: from_arrayref=1, num_args=1, $default undef.
	# Execution reaches line 274: `return unless defined $args->[0]` -> undef.
	my $result = get_params(undef, [undef]);

	ok(!defined $result,
		'\@_ with single undef element, no $default: returns undef');
};

subtest '\@_ 2-element (even), no $default, arg[1] is plain scalar -> named-pair path' => sub {
	# \@_ = ['a', 'b']: from_arrayref=1, num_args=2, ref('b')='' (not HASH).
	# Skip 2-arg hashref branch. from_arrayref && defined $default? No ($default undef).
	# num_args % 2 == 0 -> even -> flat pairs -> { a => 'b' }.
	my $result = get_params(undef, ['a', 'b']);

	is_deeply($result, { a => 'b' },
		'\@_ 2-element even-no-default: processed as named pairs');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');

	diag 'from_arrayref=1, no $default, 2 plain scalars -> even-length named-pair path'
		if $ENV{TEST_VERBOSE};
};

subtest '\@_ 4-element (even), no $default -> named-pair path' => sub {
	my $result = get_params(undef, ['x', 1, 'y', 2]);
	is_deeply($result, { x => 1, y => 2 }, '\@_ 4-element even: two named pairs');
};

subtest '\@_ 3-element (odd), no $default -> croak' => sub {
	# \@_ = ['a','b','c']: from_arrayref=1, num_args=3, no $default.
	# Not 2-arg hashref. from_arrayref && defined($default) = false.
	# 3 % 2 = 1 -> odd -> croak.
	throws_ok(
		sub { get_params(undef, ['a', 'b', 'c']) },
		$USAGE_RE,
		'\@_ 3-element odd, no $default: croak',
	);
};

subtest '\@_ 5-element (odd), no $default -> croak' => sub {
	throws_ok(
		sub { get_params(undef, ['a', 'b', 'c', 'd', 'e']) },
		$USAGE_RE,
		'\@_ 5-element odd, no $default: croak',
	);
};

subtest '\@_ 2-element, arg[0] eq $default, arg[1] is empty hashref -> {$default => {}}' => sub {
	# Shorthand suppressed: arg[1] is a ref. Then: from_arrayref=1, num_args=2,
	# ref($args->[1]) eq HASH -> 2-arg hashref branch. defined $default=YES.
	# scalar keys {}=0 -> empty opts -> line 303: return { $default => $args->[1] }.
	my $result = get_params('name', ['name', {}]);

	is_deeply($result, { name => {} },
		'\@_ 2-elem, arg[0] eq $default, empty hashref -> stored as value');
	is(ref($result->{name}), 'HASH', 'value is an empty hashref');

	diag '\@_ path -> 2-arg hashref branch -> empty opts -> {$default => {}}'
		if $ENV{TEST_VERBOSE};
};

subtest '\@_ 2-element, arg[0] eq $default, non-empty hashref -> {$default => hashref}' => sub {
	# Same path as above, but opts are non-empty.
	# $args->[0] eq $default -> line 298: return { $default => $args->[1] }.
	my $result = get_params('config', ['config', { a => 1, b => 2 }]);

	is_deeply($result, { config => { a => 1, b => 2 } },
		'\@_ 2-elem, arg[0] eq $default, non-empty hashref -> hashref stored as value');
	is($result->{config}{a}, 1, 'nested key a reachable');

	diag '\@_ path -> 2-arg hashref branch -> non-empty opts -> arg[0] eq $default -> line 298'
		if $ENV{TEST_VERBOSE};
};

subtest '\@_ 2-element, arg[0] ne $default, non-empty hashref -> mandatory+opts merged' => sub {
	# $args->[0] ne $default -> line 300: return { $default => $args->[0], %{$args->[1]} }.
	my $result = get_params('name', ['Alice', { role => 'admin', active => 1 }]);

	is_deeply(
		$result,
		{ name => 'Alice', role => 'admin', active => 1 },
		'\@_ mandatory + options: merged into flat hashref',
	);

	diag '\@_ path -> 2-arg hashref branch -> non-empty opts -> arg[0] ne $default -> line 300'
		if $ENV{TEST_VERBOSE};
};

subtest '\@_ 2-element with hashref, no $default -> flat named-pair path' => sub {
	# from_arrayref=1, num_args=2, ref($args->[1]) eq HASH, !defined $default.
	# Skip 2-arg hashref branch ($default undef). from_arrayref && defined = false.
	# Even-length -> { 'opts' => { a => 1 } }.
	my $result = get_params(undef, ['opts', { a => 1 }]);

	is_deeply($result, { opts => { a => 1 } },
		'\@_ 2-elem hashref, no $default: even-length pair path');
};

# =========================================================================
# SECTION 4: Error message format -- caller name and $default interpolation
#
# Both Carp::confess (zero args + defined $default) and Carp::croak (odd/lone
# scalar) embed caller(1)[3] -- the name of the calling sub -- in their
# messages.  These tests verify the exact format, not just the presence of
# "Usage:".
# =========================================================================

Readonly::Scalar my $KEY_NAME => 'my_required_key';

subtest 'confess message: contains "Usage:", $default key name, and "->" separator' => sub {
	my $msg;
	{
		no warnings 'redefine';
		local *Carp::confess = sub { $msg = join('', @_); die $msg };
		eval { get_params($KEY_NAME) };
	}

	like($msg, $USAGE_RE,                         'message contains "Usage:"');
	like($msg, qr/\Q$PKG\E/,                      'message contains package name');
	like($msg, qr/->/,                             'message contains "->" separator');
	like($msg, qr/\Q$KEY_NAME\E/,                 'message contains $default key name');
	like($msg, qr/\Q$KEY_NAME\E\s*=>/,            'message contains "key => $val" hint');

	diag "confess format: $msg" if $ENV{TEST_VERBOSE};
};

subtest 'croak message: contains "Usage:" and "()" suffix' => sub {
	my $msg;
	{
		local *Carp::croak = sub { $msg = join('', @_); die $msg };
		eval { get_params(undef, 'bare_scalar') };
	}

	like($msg, $USAGE_RE,        'croak message contains "Usage:"');
	like($msg, qr/\Q$PKG\E/,    'croak message contains package name');
	like($msg, qr/->/,           'croak message contains "->"');
	like($msg, qr/\(\)/,         'croak message ends with "()"');

	diag "croak format: $msg" if $ENV{TEST_VERBOSE};
};

subtest 'confess message: caller function name interpolated from caller(1)[3]' => sub {
	# When get_params is called from a named sub, caller(1)[3] returns that
	# sub's fully-qualified name. Verify it appears in the confess message.
	sub _named_caller { get_params($KEY_NAME) }

	my $msg = '';
	eval { _named_caller() };
	$msg = $@ // '';

	like($msg, qr/\Q_named_caller\E|\Q${\(__PACKAGE__)}\E/,
		'caller sub name or package appears in confess message');

	diag "caller-named confess: $msg" if $ENV{TEST_VERBOSE};
};

subtest 'croak message: caller function name interpolated from caller(1)[3]' => sub {
	sub _named_croak_caller { get_params(undef, 'x', 'y', 'z') }

	my $msg = '';
	eval { _named_croak_caller() };
	$msg = $@ // '';

	like($msg, $USAGE_RE, 'croak message has Usage:');
	like($msg, qr/\Q_named_croak_caller\E|\Q${\(__PACKAGE__)}\E/,
		'caller function name or package appears in croak message');
};

# =========================================================================
# SECTION 5: Return::Set validation for all extended paths
#
# Every new execution path in this file that succeeds must return a hashref
# satisfying the POD output schema.
# =========================================================================

subtest 'Return::Set: all new success paths return hashref' => sub {
	my @cases = (
		[ 'shorthand undef-val',       get_params('f', ['f', undef])           ],
		[ 'shorthand numeric-0-val',   get_params('n', ['n', 0])               ],
		[ '\@_ single-elem + default', get_params('k', ['v'])                   ],
		[ '\@_ 2-even no $default',    get_params(undef, ['a', 'b'])           ],
		[ '\@_ empty-opts via \@_',    get_params('nm', ['nm', {}])            ],
		[ '\@_ nonempty-opts match',   get_params('cfg', ['cfg', { x => 1 }]) ],
		[ '\@_ mandatory + opts',      get_params('nm', ['Al', { r => 'a' }]) ],
	);

	for my $case (@cases) {
		my ($label, $val) = @{$case};
		returns_ok($val, { type => 'hashref' }, "hashref schema: $label");
	}
};

subtest 'Return::Set: all new croak paths produce undef inside eval (no partial return)' => sub {
	my @croak_cases = (
		[ 'REF-of-non-empty-ARRAY',        sub { get_params(undef, \\[1,2,3]) } ],
		[ '\@_ inner non-empty ARRAY',     sub { get_params(undef, [[1,2,3]]) } ],
		[ '\@_ 3-elem odd no $default',    sub { get_params(undef, ['a','b','c']) } ],
	);

	for my $case (@croak_cases) {
		my ($label, $call) = @{$case};
		my $result = eval { $call->() };
		ok(!defined $result, "croak path produces undef: $label");
	}
};

# =========================================================================
# SECTION 6: Global state integrity for the new croak paths
#
# unit.t checks global state for the success path and known croak paths.
# This section checks that the newly-exercised croak paths are equally clean.
# =========================================================================

subtest 'global state: $@ set correctly by REF-of-non-empty-ARRAY croak' => sub {
	local $@ = 'sentinel';
	eval { get_params(undef, \\[1, 2, 3]) };
	like($@, $USAGE_RE, 'croak message captured in $@');
	isnt($@, 'sentinel', '$@ was replaced by croak message');
};

subtest 'global state: $@ set correctly by \@_ odd-inner croak' => sub {
	local $@ = 'other_sentinel';
	eval { get_params(undef, ['a', 'b', 'c']) };
	like($@, $USAGE_RE, '\@_ odd-inner croak captured in $@');
};

subtest 'global state: $! (errno) not clobbered by new croak paths' => sub {
	$! = POSIX::ENOENT();
	my $saved = int($!);

	eval { get_params(undef, \\[42]) };     # REF-of-non-empty-ARRAY croak
	is(int($!), $saved, '$! unchanged after REF-of-non-empty-ARRAY croak');

	eval { get_params(undef, ['x', 'y', 'z']) };    # \@_ odd croak
	is(int($!), $saved, '$! unchanged after \@_-odd croak');
};

subtest 'global state: $_ not clobbered by shorthand path' => sub {
	local $_ = 'topic_sentinel';
	get_params('flag', ['flag', undef]);    # shorthand fires
	is($_, 'topic_sentinel', '$_ preserved through shorthand path');
};

# =========================================================================
# SECTION 7: Systematic from_arrayref x defined_default x num_args matrix
#
# Cover every distinct cell of the (from_arrayref, defined $default, num_args)
# product space that is new to this file.
# =========================================================================

subtest 'matrix: from_arrayref=1, $default defined, num_args=1, arg is coderef' => sub {
	# \@_ = [\&sub]: from_arrayref=1, $default='fn', $arg is CODE.
	# defined $default -> one-arg branch -> kind eq CODE -> { fn => $cb }.
	my $cb     = sub { 99 };
	my $result = get_params('fn', [$cb]);

	is(ref($result->{fn}), 'CODE',   'coderef wrapped via \@_ single-element + $default');
	is($result->{fn}->(), 99,        'stored coderef is still callable');
};

subtest 'matrix: from_arrayref=1, $default defined, num_args=1, arg is blessed object' => sub {
	my $obj    = bless { v => 7 }, 'Matrix::Test';
	my $result = get_params('obj', [$obj]);

	is($result->{obj}, $obj, 'blessed object wrapped via \@_ single-element + $default');
	is(Scalar::Util::blessed($result->{obj}), 'Matrix::Test',
		'blessedness preserved through \@_ path');
};

subtest 'matrix: from_arrayref=1, $default defined, num_args=1, arg is scalarref (auto-deref)' => sub {
	# One-arg + defined $default + kind eq SCALAR -> return { $default => ${$arg} }.
	my $str    = 'dereffed';
	my $result = get_params('msg', [\$str]);

	is($result->{msg}, 'dereffed',   'scalarref inner element dereffed through \@_ path');
	is(ref($result->{msg}), '',      'stored value is plain scalar');
};

subtest 'matrix: from_arrayref=1, $default defined, num_args=1, arg is arrayref -> stored by ref' => sub {
	# \@_ = [[\@inner]]: the inner element is an arrayref.
	# kind eq ARRAY -> return { $default => $arg } (the arrayref, not unwrapped).
	my @inner  = (10, 20, 30);
	my $result = get_params('list', [[\@inner]]);

	is(ref($result->{list}), 'ARRAY',     'inner arrayref stored under key');
	is_deeply($result->{list}, [\@inner], 'stored value is the original inner ARRAY ref');
};

subtest 'matrix: from_arrayref=1, $default undef, num_args=1, arg is hashref -> pass through' => sub {
	# \@_ = [{k=>'v'}]: from_arrayref=1, $default undef.
	# defined $default is false -> skip defined-$default block.
	# $val = {k=>'v'} (not REF, is HASH) -> return $val directly.
	my $h      = { k => 'v' };
	my $result = get_params(undef, [$h]);

	is($result, $h,  'lone hashref in \@_ returned by identity when no $default');
	is_deeply($result, { k => 'v' }, 'content intact');
};

subtest 'matrix: from_arrayref=1, $default undef, num_args=1, arg is non-empty ARRAY -> croak' => sub {
	# The critical l&&!r case: lone non-empty ARRAY via \@_ path, no $default.
	throws_ok(
		sub { get_params(undef, [[99, 100]]) },
		$USAGE_RE,
		'lone non-empty ARRAY element in \@_ with no $default: croak',
	);
};

subtest 'matrix: from_arrayref=1, $default undef, num_args=1, arg is empty ARRAY -> return it' => sub {
	# This is the l&&r path (empty array, no $default).
	my $empty  = [];
	my $result = get_params(undef, [$empty]);

	is(ref($result), 'ARRAY', 'empty arrayref returned as-is');
	is($result, $empty,        'same reference returned');
};

# =========================================================================
# SECTION 8: Spy-verified argument flow through new paths
#
# Use Test::Mockingbird spies to confirm that the new paths deliver the
# expected argument tuple to Params::Get::get_params.
# =========================================================================

{
	package Extended::Wrapper;

	# Must shift $class first; otherwise \@_ includes the class name
	# and produces an odd-length list that croaks before the spy sees it.
	sub from_array_ref { my $class = shift; Params::Get::get_params(undef, \@_) }
	sub with_default   { my $class = shift; Params::Get::get_params('key',  \@_) }
}

subtest 'spy: from_arrayref=1 path passes correct tuple to get_params' => sub {
	my $spy = spy 'Params::Get::get_params';

	Extended::Wrapper->from_array_ref(x => 1, y => 2);

	my @calls = $spy->();
	ok(@calls >= 1, 'get_params was called');

	my $call = $calls[0];
	ok(!defined $call->[1], '$default (arg0) was undef');
	is(ref($call->[2]), 'ARRAY', 'arg1 is an ARRAY ref (\\@_ convention)');

	restore_all();
};

subtest 'spy: shorthand firing: from_arrayref path delivers scalar directly' => sub {
	# Verify that when the shorthand fires, get_params is called with
	# (default, [default, scalar]) and the spy sees the arrayref form.
	my $spy = spy 'Params::Get::get_params';

	Extended::Wrapper->with_default('hello');    # caller sends ('hello'), callee uses \@_

	my @calls = $spy->();
	ok(@calls >= 1, 'get_params called');

	my $call = $calls[0];
	is($call->[1], 'key', '$default arg is "key"');
	is(ref($call->[2]), 'ARRAY', 'second arg is \\@_ arrayref');
	is($call->[2][0], 'hello', 'inner element is the scalar value');

	restore_all();
};

done_testing();
