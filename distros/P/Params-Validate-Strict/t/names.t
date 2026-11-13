#!/usr/bin/env perl

# Tests needs, element_isa, can for invocant, and classcan.

use strict;
use warnings;
use Test::Most;

use Params::Validate::Strict qw(validate_strict);

{
	package Local::Thing;
	sub new { bless {}, shift }
	sub run { 1 }
	package Local::Sub;
	our @ISA = ('Local::Thing');
}

# ── needs ────────────────────────────────────────────────────────────────────

my $needs_schema = {
	user => { type => 'string', optional => 1, needs => ['password', 'realm'] },
	password => { type => 'string', optional => 1 },
	realm    => { type => 'string', optional => 1 },
};

lives_ok { validate_strict(schema => $needs_schema, input => {}) }
	'needs: absent parameter imposes no requirement';
lives_ok { validate_strict(schema => $needs_schema, input => { user => 'u', password => 'p', realm => 'r' }) }
	'needs: all needed parameters present';
throws_ok { validate_strict(schema => $needs_schema, input => { user => 'u', password => 'p' }) }
	qr/user requires realm/, 'needs: second needed parameter missing is reported';
throws_ok { validate_strict(schema => $needs_schema, input => { user => 'u', realm => 'r' }) }
	qr/user requires password/, 'needs: first needed parameter missing is reported';
throws_ok {
	validate_strict(
		schema => { a => { type => 'string', needs => 'b' }, b => { type => 'string', optional => 1 } },
		input => { a => 'x' },
	)
} qr/a requires b/, 'needs: a plain string is accepted for a single dependency';
throws_ok {
	validate_strict(
		schema => { a => { type => 'string', needs => {} }, b => { type => 'string', optional => 1 } },
		input => { a => 'x', b => 'y' },
	)
} qr/needs.*must be a string or an arrayref/, 'needs: hashref value is rejected';

# needs coexists with an explicit relationships list
throws_ok {
	validate_strict(
		schema => {
			a => { type => 'string', optional => 1, needs => 'b' },
			b => { type => 'string', optional => 1 },
			c => { type => 'string', optional => 1 },
		},
		relationships => [{ type => 'dependency', param => 'c', requires => 'a' }],
		input => { c => 'z' },
	)
} qr/c requires a/, 'needs: explicit relationships still run alongside needs';

# ── element_isa ──────────────────────────────────────────────────────────────

my $isa_schema = { things => { type => 'arrayref', element_isa => 'Local::Thing' } };

lives_ok { validate_strict(schema => $isa_schema, input => { things => [Local::Thing->new, Local::Sub->new] }) }
	'element_isa: objects and subclass objects accepted';
lives_ok { validate_strict(schema => $isa_schema, input => { things => [] }) }
	'element_isa: empty arrayref accepted';
throws_ok { validate_strict(schema => $isa_schema, input => { things => [Local::Thing->new, 'Local::Thing'] }) }
	qr/can only contain 'Local::Thing' objects/, 'element_isa: class-name string rejected (not an object)';
throws_ok { validate_strict(schema => $isa_schema, input => { things => [bless({}, 'Other')] }) }
	qr/can only contain 'Local::Thing' objects/, 'element_isa: unrelated object rejected';
throws_ok { validate_strict(schema => { t => { type => 'string', element_isa => 'Local::Thing' } }, input => { t => 'x' }) }
	qr/meaningless element_isa/, 'element_isa: non-arrayref type is rejected';

# ── can with type => invocant ────────────────────────────────────────────────

my $inv = { i => { type => 'invocant', can => 'run' } };

lives_ok { validate_strict(schema => $inv, input => { i => 'Local::Thing' }) } 'invocant+can: class name that can';
lives_ok { validate_strict(schema => $inv, input => { i => Local::Thing->new }) } 'invocant+can: object that can';
throws_ok { validate_strict(schema => { i => { type => 'invocant', can => 'nope' } }, input => { i => 'Local::Thing' }) }
	qr/understands the nope method/, 'invocant+can: class name that cannot';
throws_ok { validate_strict(schema => { i => { type => 'invocant', can => 'nope' } }, input => { i => Local::Thing->new }) }
	qr/understands the nope method/, 'invocant+can: object that cannot';
throws_ok { validate_strict(schema => { i => { type => 'invocant', can => ['run', 'nope'] } }, input => { i => 'Local::Thing' }) }
	qr/understands the nope method/, 'invocant+can: arrayref of methods, one missing';
throws_ok { validate_strict(schema => { s => { type => 'string', can => 'run' } }, input => { s => 'Local::Thing' }) }
	qr/meaningless can/, 'can: still meaningless for plain strings';

# ── classcan ─────────────────────────────────────────────────────────────────

lives_ok { validate_strict(schema => { c => { type => 'string', classcan => 'run' } }, input => { c => 'Local::Thing' }) }
	'classcan: class that can';
lives_ok { validate_strict(schema => { c => { type => 'string', classcan => ['run', 'new'] } }, input => { c => 'Local::Sub' }) }
	'classcan: inherited methods count; arrayref of methods';
throws_ok { validate_strict(schema => { c => { type => 'string', classcan => 'nope' } }, input => { c => 'Local::Thing' }) }
	qr/understands the nope method/, 'classcan: missing method';
throws_ok { validate_strict(schema => { c => { type => 'string', classcan => ['run', 'nope'] } }, input => { c => 'Local::Thing' }) }
	qr/understands the nope method/, 'classcan: one of several methods missing';
throws_ok { validate_strict(schema => { c => { type => 'string', classcan => 'run' } }, input => { c => Local::Thing->new }) }
	qr/must be a string/, 'classcan: object rejected (by the string type check)';
throws_ok { validate_strict(schema => { c => { type => 'string', classcan => 'run' } }, input => { c => 'not a class' }) }
	qr/must be a valid class name/, 'classcan: malformed class name rejected';
throws_ok { validate_strict(schema => { c => { type => 'string', classcan => {} } }, input => { c => 'Local::Thing' }) }
	qr/classcan.*scalar or an arrayref/, 'classcan: hashref rule value rejected';
lives_ok { validate_strict(schema => { c => { type => 'string', optional => 1, classcan => 'run' } }, input => {}) }
	'classcan: absent optional parameter skipped';

done_testing();
