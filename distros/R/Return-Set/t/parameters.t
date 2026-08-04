use strict;
use warnings;

use Test::Most;
use Return::Set qw(set_return);

# Parameter-dispatch proof suite
# --------------------------------
# These tests prove the key-selection and dispatch invariants that are internal
# to the named-parameter form and are orthogonal to schema validation.
#
#   Invariant A: 'output' key is preferred over 'value' key.
#   Invariant B: 'value' key is accepted as a backwards-compatible synonym.
#   Invariant C: when both keys are present, 'output' wins (preference ordering).

# --- Invariant A: 'output' key (primary) ----------------------------------
# Major: 'output' is the canonical key for the named-parameter form.
# Minor: hashref contains only 'output'.
# Conclusion: that value is returned.
is set_return({ output => 'primary' }), 'primary',
	'InvA: output key extracted correctly';

# --- Invariant B: 'value' key (backwards compat) --------------------------
# Major: 'value' is accepted for backwards compatibility when 'output' is absent.
# Minor: hashref contains only 'value'.
# Conclusion: that value is returned.
is set_return({ value => 'compat' }), 'compat',
	'InvB: value key accepted as backwards-compatible synonym';

# --- Invariant C: 'output' takes precedence over 'value' ------------------
# Major: when both keys are present, 'output' is preferred.
# Minor: hashref contains output => 'wins' and value => 'loses'.
# Conclusion: 'wins' is returned, proving 'output' is evaluated first.
is set_return({ output => 'wins', value => 'loses' }), 'wins',
	'InvC: output key takes precedence over value key when both present';

# --- Dispatch boundary: positional vs named --------------------------------
# Major: exactly 2 arguments triggers the positional path (not Params::Get).
# Minor: (99, undef) → value=99, schema=undef.
# Conclusion: 99 is returned without schema validation.
is set_return(99, undef), 99,
	'Boundary: 2-arg positional path does not route through named-param dispatch';

# --- Dispatch boundary: named form with schema ----------------------------
# Major: a valid named-form hashref with schema triggers validation.
# Minor: output => 99, schema => integer.  99 satisfies integer.
# Conclusion: 99 is returned after validation.
is set_return({ output => 99, schema => { type => 'integer' } }), 99,
	'Boundary: named-form dispatches correctly with schema';

# --- Dispatch boundary: named form, schema violation ----------------------
throws_ok { set_return({ value => ['a'], schema => { type => 'integer' } }) }
	qr/Validation failed/,
	'Boundary: named-form value-key schema violation croaks correctly';

done_testing();
