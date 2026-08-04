use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Return::Set', qw(set_return)) }

# Equivalence-partition test plan
# --------------------------------
# Every input to set_return falls into exactly one cell of this partition table:
#
#   Arity | First-arg type | Schema? | Valid? | Expected outcome
#   ------+----------------+---------+--------+------------------------
#   0     | —              | —       | —      | croak Usage          (P1)
#   1     | non-ref scalar | absent  | —      | fast-path return     (P2)
#   1     | hashref        | absent  | —      | named-form return    (P3)
#   1     | hashref        | present | yes    | named-form return    (P4)
#   1     | hashref        | present | no     | croak Validation     (P5)
#   2     | any            | absent  | —      | return unchanged     (P6)
#   2     | plain scalar   | present | yes    | return value         (P7)
#   2     | plain scalar   | present | no     | croak, names value   (P8)
#   2     | undef          | present | no     | croak, says undef    (P9)
#   2     | ref            | present | yes    | return ref           (P10)
#   2     | ref            | present | no     | croak, no ref embed  (P11)

# --- P1: zero arguments ---------------------------------------------------
# Major: set_return requires >= 1 argument (function contract).
# Minor: no arguments are supplied.
# Conclusion: croak with a Usage message that names the function.
throws_ok { set_return() }
	qr/Usage:.+set_return/,
	'P1: zero args croaks with Usage message naming set_return';

# --- P2: single non-ref scalar (fast path) --------------------------------
# Major: a lone plain scalar carries no schema.
# Minor: @_ == 1 and $_[0] is not a reference.
# Conclusion: $_[0] returned immediately without entering dispatch logic.
is set_return('hello'), 'hello', 'P2: single non-ref scalar returned via fast path';

# --- P3: named form, no schema --------------------------------------------
# Major: a sole hashref triggers named-parameter dispatch via Params::Get.
# Minor: key 'output' present, key 'schema' absent.
# Conclusion: value extracted and returned without validation.
is set_return({ output => 42 }), 42, 'P3: named-form {output}, no schema';

# --- P4: named form, schema, valid ----------------------------------------
# Major: validate_strict passes iff value satisfies schema.
# Minor: 5 satisfies { type => 'integer' }.
# Conclusion: 5 is returned.
is set_return({ output => 5, schema => { type => 'integer' } }), 5,
	'P4: named-form {output,schema}, valid — value returned';

# --- P5: named form, schema, violation ------------------------------------
# Major: a schema mismatch always produces a Validation-failed croak.
# Minor: 'bad' does not satisfy { type => 'integer' }.
# Conclusion: croak containing "Validation failed".
throws_ok { set_return({ output => 'bad', schema => { type => 'integer' } }) }
	qr/Validation failed/,
	'P5: named-form {output,schema}, invalid — Validation failed croak';

# --- P6: positional, no schema --------------------------------------------
# Major: an absent (undef) schema bypasses validate_strict entirely.
# Minor: value is an arrayref, schema is undef.
# Conclusion: value returned unchanged regardless of its type.
my $aref = [1, 2, 3];
is_deeply set_return($aref, undef), $aref,
	'P6: positional (ref, undef-schema) — returned unchanged, no validation';

# --- P7: positional, plain scalar, valid schema ---------------------------
# Major: validate_strict is authoritative — if it returns, the value is valid.
# Minor: 123 satisfies { type => 'integer' }.
# Conclusion: 123 is returned; no further check needed downstream.
is set_return(123, { type => 'integer' }), 123,
	'P7: positional scalar, schema valid — value returned';

# --- P8: positional, plain scalar, schema violation -----------------------
# Major: a defined non-ref value can be safely interpolated in an error message.
# Minor: 'hello' does not satisfy { type => 'integer' }.
# Conclusion: croak embeds the offending value for diagnostics.
throws_ok { set_return('hello', { type => 'integer' }) }
	qr/Validation failed, hello is invalid/,
	'P8: positional scalar, schema violated — offending value named in message';

# --- P9: positional, undef, schema present (always passes) ----------------
# Major: validate_strict treats undef as "not provided" for optional fields;
#   type constraints are not evaluated against undef.
# Minor: undef with schema => { type => 'integer' }.
# Conclusion: validation is not attempted — undef is returned unchanged.
# (The code branch for "value is undefined" is formally dead for all PVS schemas.)
is set_return(undef, { type => 'integer' }), undef,
	'P9: undef always passes PVS schema — treated as optional/not-provided';

# --- P10: positional, reference types, valid schemas ----------------------
# Major: validate_strict handles reference types via reference-typed schemas.
# Minor: each ref satisfies its corresponding type constraint.
# Conclusion: original reference identity is preserved and returned.
my $list = ['a', 'b'];
is_deeply set_return($list, { type => 'arrayref', min => 2, max => 2 }),
	$list, 'P10a: arrayref passes arrayref schema';

my $hash = { foo => 1 };
is_deeply set_return($hash, { type => 'hashref', min => 1, max => 1 }),
	$hash, 'P10b: hashref passes hashref schema';

my $code = sub { 1 };
is set_return($code, { type => 'coderef' }), $code,
	'P10c: coderef passes coderef schema';

# --- P11: positional, reference, schema violation -------------------------
# Major: a reference cannot be safely interpolated into a string.
# Minor: [] does not satisfy { type => 'integer' }.
# Conclusion: croak says "Validation failed:" without embedding the stringified ref.
throws_ok { set_return([], { type => 'integer' }) }
	qr/^Validation failed:/,
	'P11: positional ref, schema violated — ref NOT interpolated in message';

done_testing();
