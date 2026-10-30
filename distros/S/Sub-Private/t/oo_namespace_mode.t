use strict;
use warnings;
use Test::Most;

# Regression test: namespace mode breaks OO method dispatch.
#
# In namespace mode (the default since 0.07), :Private subs are removed from
# the package symbol table.  Direct function calls compiled before the removal
# still work because they hold a code reference.  But OO dispatch ($self->_method)
# looks up the method in the symbol table at runtime and finds nothing.
#
# When the class defines AUTOLOAD, the failed lookup falls through silently:
# AUTOLOAD returns whatever it returns (often undef) with no error.  This is
# the failure mode that went undetected in Database::Abstraction 0.51 --
# _merge_base_criteria :Private was removed, OO calls returned undef, and
# every query criterion was silently discarded.
#
# The fix is always: use Sub::Private { mode => 'enforce' } in OO code.

# ---------------------------------------------------------------
# Fixture: OO class using DEFAULT (namespace) mode.
# The :Private sub is removed from the stash; $self->_priv fails.
# ---------------------------------------------------------------

{
	package NsOO;
	use Sub::Private;    # namespace mode: _priv is removed

	sub new     { bless {}, shift }
	sub _priv   :Private { 'private result' }
	sub via_oo  { (shift)->_priv }    # OO dispatch -- breaks in namespace mode
}

# ---------------------------------------------------------------
# Fixture: OO class with AUTOLOAD + namespace mode.
# This is the silent-failure case: OO call falls through to AUTOLOAD,
# which returns undef with no error -- callers get wrong data silently.
# Mirrors Database::Abstraction, which has an AUTOLOAD that rejects
# underscore-prefixed names (a security guard) and returns undef for them.
# ---------------------------------------------------------------

{
	package NsOOAutoload;
	use Sub::Private;    # namespace mode

	our $AUTOLOAD;

	sub new       { bless {}, shift }
	sub _helper   :Private { 'helper result' }
	sub call_it   { (shift)->_helper }    # silently broken in namespace mode

	# Simulates Database::Abstraction's AUTOLOAD security guard:
	# underscore-prefixed names are rejected (returns undef).
	sub AUTOLOAD {
		my $name = $AUTOLOAD;
		$name =~ s/.*:://;
		return if $name eq 'DESTROY';
		return undef if $name =~ /^_/;    # SEC7-style guard
		return "autoload:$name";
	}
	sub DESTROY {}
}

# ---------------------------------------------------------------
# Fixture: OO class that computes a value via a :Private helper and
# also defines AUTOLOAD -- demonstrating the silent wrong-value failure
# that hits any computed result flowing through a :Private method.
# ---------------------------------------------------------------

{
	package NsCompute;
	use Sub::Private;    # namespace mode

	our $AUTOLOAD;

	sub new        { bless {}, shift }
	sub _criteria  :Private { { status => 'active' } }
	sub get_filter { (shift)->_criteria }    # returns undef in namespace mode

	# Simulates the AUTOLOAD security guard seen in real OO modules.
	sub AUTOLOAD {
		my $name = $AUTOLOAD;
		$name =~ s/.*:://;
		return if $name eq 'DESTROY';
		return undef if $name =~ /^_/;
		return "autoload:$name";
	}
	sub DESTROY {}
}

# ---------------------------------------------------------------
# Fixture: OO class using enforce mode -- the correct choice for OO.
# ---------------------------------------------------------------

{
	package EnfOO;
	use Sub::Private { mode => 'enforce' };

	sub new    { bless {}, shift }
	sub _priv  :Private { 'private result' }
	sub via_oo { (shift)->_priv }
}

{
	package EnfCompute;
	use Sub::Private { mode => 'enforce' };

	sub new        { bless {}, shift }
	sub _criteria  :Private { { status => 'active' } }
	sub get_filter { (shift)->_criteria }    # returns correct value
}

# ---------------------------------------------------------------
# Tests
# ---------------------------------------------------------------

local $ENV{HARNESS_ACTIVE}  = 0;
local $Sub::Private::BYPASS = 0;

# ---- Section 1: namespace mode removes the sub from the symbol table ----

subtest 'namespace mode: :Private sub is absent from symbol table' => sub {
	plan tests => 2;
	ok(!NsOO->can('_priv'),
		'namespace mode: can("_priv") returns false (sub removed from stash)');
	ok(!NsOOAutoload->can('_helper'),
		'namespace mode: can("_helper") returns false (sub removed from stash)');
};

# ---- Section 2: OO dispatch fails in namespace mode without AUTOLOAD ----

subtest 'namespace mode (no AUTOLOAD): OO dispatch dies with "method not found"' => sub {
	plan tests => 2;

	# Without AUTOLOAD: dies with "Can't locate object method"
	throws_ok { NsOO->new->via_oo }
		qr/Can't locate object method "_priv"/,
		'namespace mode: $self->_private dies -- method removed from stash';

	# Crucially, the error says nothing about privacy -- the caller gets
	# a generic "method not found" message, not the informative
	# "_priv() is a private subroutine" croak from enforce mode.
	my $err;
	eval { NsOO->new->via_oo };
	$err = $@;
	unlike($err, qr/private subroutine/,
		'namespace mode failure gives a generic error, not a clear privacy croak');
};

# ---- Section 3: the silent AUTOLOAD failure mode ----

subtest 'namespace mode + AUTOLOAD: OO call silently returns undef' => sub {
	plan tests => 3;

	# This is the most dangerous case: no exception, wrong return value.
	my $result;
	lives_ok { $result = NsOOAutoload->new->call_it }
		'namespace mode + AUTOLOAD: $self->_helper does NOT throw (falls through to AUTOLOAD)';

	is($result, undef,
		'namespace mode + AUTOLOAD: return value is undef (AUTOLOAD swallowed the call)');

	isnt($result, 'helper result',
		'namespace mode + AUTOLOAD: caller receives wrong answer with no error');
};

# ---- Section 4: the silent wrong-value failure for computed results ----

subtest 'namespace mode + AUTOLOAD: computed value is silently lost' => sub {
	plan tests => 2;

	# Simulates what happened in Database::Abstraction:
	# _merge_base_criteria returned undef, so criteria were discarded.
	my $filter;
	lives_ok { $filter = NsCompute->new->get_filter }
		'namespace mode: get_filter() lives (OO call falls through to AUTOLOAD)';

	is($filter, undef,
		'namespace mode: filter is undef -- _criteria silently discarded by AUTOLOAD');
};

# ---- Section 5: enforce mode preserves OO dispatch ----

subtest 'enforce mode: OO dispatch works correctly' => sub {
	plan tests => 3;

	ok(EnfOO->can('_priv'),
		'enforce mode: can("_priv") returns the wrapper (sub stays in stash)');

	my $result;
	lives_ok { $result = EnfOO->new->via_oo }
		'enforce mode: $self->_private lives';

	is($result, 'private result',
		'enforce mode: correct return value through OO dispatch');
};

subtest 'enforce mode: computed value flows correctly' => sub {
	plan tests => 2;

	my $filter;
	lives_ok { $filter = EnfCompute->new->get_filter }
		'enforce mode: get_filter() lives';

	is_deeply($filter, { status => 'active' },
		'enforce mode: correct hashref returned through OO dispatch');
};

# ---- Section 6: enforce mode still blocks external callers ----

subtest 'enforce mode: OO dispatch works for owner, still blocks outsiders' => sub {
	plan tests => 2;
	lives_ok { EnfOO->new->via_oo }
		'enforce mode: owner OO call lives';

	throws_ok { EnfOO->new->_priv }
		qr/private subroutine/,
		'enforce mode: external call to _priv still blocked with clear error';
};

# ---- Section 7: fix summary -- the migration rule ----

subtest 'migration rule: bare use Sub::Private is unsafe for OO classes' => sub {
	plan tests => 3;

	# namespace mode: sub removed -- OO dispatch fails or silently misbehaves
	ok(!NsOO->can('_priv'),
		'namespace mode: method absent from stash, OO dispatch cannot find it');

	# enforce mode: sub present as wrapper -- OO dispatch works, outsiders blocked
	ok(EnfOO->can('_priv'),
		'enforce mode: method present in stash as wrapper, OO dispatch succeeds');

	# The only safe option for OO classes is explicit enforce mode
	my $ok;
	lives_ok { $ok = EnfOO->new->via_oo }
		'enforce mode: use Sub::Private { mode => "enforce" } is the correct choice for OO classes';
};

done_testing;
