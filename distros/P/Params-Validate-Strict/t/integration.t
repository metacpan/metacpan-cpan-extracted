#!/usr/bin/env perl

# Integration tests for Params::Validate::Strict.
# Exercises end-to-end behaviour, stateful usage, feature combinations, and
# confirmed integration with each package in the dependency stack.
# use_ok verifies every dependency is present; new_ok creates test objects.

use strict;
use warnings;
use Test::Most;
use Encode     qw(encode);		# for byte-string tests
use Scalar::Util qw(blessed looks_like_number);
use List::Util 1.33;	# version check; called as List::Util::any() below to avoid
			# clashing with Test::Deep's any() which Test::Most loads

# ── Load the module under test ────────────────────────────────────────────────
BEGIN { use_ok('Params::Validate::Strict', 'validate_strict') }

# ── Confirm the full dependency stack is available ────────────────────────────
# These use_ok calls are availability assertions; the compile-time 'use'
# statements above are what actually put the symbols into scope.
use_ok('Params::Get');
use_ok('Scalar::Util',       qw(blessed looks_like_number));
# List::Util already loaded with correct version above; just assert it here.
cmp_ok(List::Util->VERSION, '>=', '1.33', 'List::Util 1.33+ available (any() present)');
use_ok('Unicode::GCString');
use_ok('Encode',             qw(decode_utf8));
use_ok('Carp');
use_ok('Readonly::Values::Boolean');

# ── Test-support classes ──────────────────────────────────────────────────────

{
	package Int::User;
	sub new    { bless { name => $_[1], role => $_[2] }, $_[0] }
	sub name   { $_[0]{name} }
	sub role   { $_[0]{role} }
	sub greet  { "Hello, " . $_[0]{name} }
}
{
	package Int::AdminUser;
	our @ISA = ('Int::User');
	sub new          { my $c = shift; bless $c->SUPER::new(@_), $c }
	sub admin_action { 1 }
}
{
	package Int::GedcomFile;
	sub new            { bless {}, shift }
	sub get_individual { {} }
	sub get_family     { {} }
}

# ── new_ok: verify test classes construct correctly ───────────────────────────

my $user   = new_ok('Int::User',      ['Alice', 'viewer'], 'Int::User object');
my $admin  = new_ok('Int::AdminUser', ['Bob',   'admin' ], 'Int::AdminUser object');
my $gedcom = new_ok('Int::GedcomFile', [],                 'Int::GedcomFile object');

# ══════════════════════════════════════════════════════════════════════════════
# Params::Get integration — calling conventions
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Params::Get: named args style' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'string' } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'named args passed through Params::Get correctly');
};

subtest 'Params::Get: single-hashref calling style' => sub {
	my $r = validate_strict({
		schema => { x => { type => 'string' } },
		input  => { x => 'hello' },
	});
	is($r->{x}, 'hello', 'single hashref calling style works');
};

subtest 'Params::Get: args/members aliases' => sub {
	my $r = validate_strict(
		members => { x => { type => 'string' } },
		args    => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'members/args aliases handled by Params::Get');
};

subtest 'Params::Get: named style and hashref style produce identical results' => sub {
	my $schema = { n => { type => 'integer', min => 1 } };
	my $input  = { n => '7' };
	my $r1 = validate_strict(schema => $schema, input => $input);
	my $r2 = validate_strict({ schema => $schema, input => $input });
	is_deeply($r1, $r2, 'named and hashref calling styles return identical results');
};

# ══════════════════════════════════════════════════════════════════════════════
# Scalar::Util integration
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Scalar::Util::blessed: blessed object accepted for type object' => sub {
	ok(blessed($user), 'Int::User is blessed (Scalar::Util confirms)');
	my $r = validate_strict(
		schema => { u => { type => 'object' } },
		input  => { u => $user },
	);
	is($r->{u}, $user, 'validate_strict accepts the blessed ref');
};

subtest 'Scalar::Util::blessed: unblessed ref rejected for type object' => sub {
	my $plain = {};	# not blessed
	ok(!blessed($plain), 'plain hashref is not blessed (Scalar::Util confirms)');
	throws_ok {
		validate_strict(
			schema => { u => { type => 'object' } },
			input  => { u => $plain },
		)
	} qr/must be an object/, 'validate_strict rejects unblessed ref';
};

subtest 'Scalar::Util::looks_like_number: values that look numeric pass' => sub {
	for my $v (qw(0 1 -7 3.14 2.5e3)) {
		ok(looks_like_number($v), "'$v' looks_like_number (Scalar::Util)");
		lives_ok {
			validate_strict(
				schema => { n => { type => 'number' } },
				input  => { n => $v },
			)
		} "'$v' accepted as number by validate_strict";
	}
};

subtest 'Scalar::Util::blessed: isa check uses Perl inheritance correctly' => sub {
	ok(blessed($admin),            'admin is blessed');
	ok($admin->isa('Int::User'),   'admin ISA Int::User (Scalar::Util confirms)');
	lives_ok {
		validate_strict(
			schema => { u => { type => 'object', isa => 'Int::User' } },
			input  => { u => $admin },
		)
	} 'isa satisfied through inheritance';
};

subtest 'Scalar::Util::blessed: can check dispatches correctly' => sub {
	ok($gedcom->can('get_individual'), 'Int::GedcomFile can get_individual');
	lives_ok {
		validate_strict(
			schema => { g => { type => 'object', can => ['get_individual', 'get_family'] } },
			input  => { g => $gedcom },
		)
	} 'can check for multiple methods passes';
};

# ══════════════════════════════════════════════════════════════════════════════
# List::Util integration (memberof/notmemberof use List::Util::any)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'List::Util::any: memberof uses any() under the hood' => sub {
	my @roles = qw(admin viewer editor);
	# Directly verify List::Util::any agrees with the memberof outcome
	ok(List::Util::any(sub { $_ eq 'viewer' }, @roles), 'List::Util::any() finds viewer in list');
	my $r = validate_strict(
		schema => { role => { type => 'string', memberof => \@roles } },
		input  => { role => 'viewer' },
	);
	is($r->{role}, 'viewer', 'memberof accepts value that any() would find');
};

subtest 'List::Util::any: numeric memberof uses == not eq' => sub {
	my @levels = (1, 2, 3, 4, 5);
	ok(List::Util::any(sub { $_ == 3 }, @levels), 'List::Util::any() with == finds 3 in list');
	my $r = validate_strict(
		schema => { lvl => { type => 'integer', memberof => \@levels } },
		input  => { lvl => '3' },
	);
	is($r->{lvl}, 3, 'integer memberof after coercion: numeric equality used');
};

subtest 'List::Util::any: notmemberof uses any() for blacklist check' => sub {
	my @banned = qw(admin root system);
	ok(List::Util::any(sub { $_ eq 'admin' }, @banned), 'List::Util::any() finds admin in blacklist');
	throws_ok {
		validate_strict(
			schema => { user => { type => 'string', notmemberof => \@banned } },
			input  => { user => 'admin' },
		)
	} qr/must not be one of/, 'notmemberof croaks for blacklisted value';
};

# ══════════════════════════════════════════════════════════════════════════════
# Readonly::Values::Boolean integration
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Readonly::Values::Boolean: all defined boolean values accepted' => sub {
	my %booleans = %Readonly::Values::Boolean::booleans;
	ok(scalar keys %booleans > 0, 'booleans hash is populated');

	for my $val (keys %booleans) {
		my $r = validate_strict(
			schema => { b => { type => 'boolean' } },
			input  => { b => $val },
		);
		if($booleans{$val}) {
			ok($r->{b},  "'$val' coerced to truthy (agrees with booleans hash)");
		} else {
			ok(!$r->{b}, "'$val' coerced to falsy (agrees with booleans hash)");
		}
	}
};

subtest 'Readonly::Values::Boolean: undefined boolean string rejected' => sub {
	ok(!exists $Readonly::Values::Boolean::booleans{'maybe'},
		'"maybe" not in booleans hash');
	throws_ok {
		validate_strict(
			schema => { b => { type => 'boolean' } },
			input  => { b => 'maybe' },
		)
	} qr/must be a boolean/, 'validate_strict rejects value not in booleans hash';
};

# ══════════════════════════════════════════════════════════════════════════════
# Unicode::GCString integration (real grapheme-cluster counting)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Unicode::GCString: Japanese string — grapheme clusters, not bytes' => sub {
	my $str = "\x{65e5}\x{672c}\x{8a9e}";	# 日本語 — 3 chars, 9 UTF-8 bytes
	my $gcstr = Unicode::GCString->new($str);
	is($gcstr->length, 3, 'GCString reports 3 for 3 Japanese characters');
	cmp_ok(length(encode('UTF-8', $str)), '>', 3, 'UTF-8 byte count is > 3');

	my $r = validate_strict(
		schema => { s => { type => 'string', min => 3, max => 3 } },
		input  => { s => $str },
	);
	is($r->{s}, $str, '3-char Japanese string satisfies min=>3,max=>3');
};

subtest 'Unicode::GCString: min fails when grapheme count is short' => sub {
	my $str = "\x{65e5}\x{672c}";	# 日本 — 2 chars
	my $gcstr = Unicode::GCString->new($str);
	is($gcstr->length, 2, 'GCString confirms 2 grapheme clusters');
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', min => 3 } },
			input  => { s => $str },
		)
	} qr/too short/, '2-char string fails min=>3 by grapheme count';
};

subtest 'Unicode::GCString: Latin-extended string — accented characters' => sub {
	my $str = "\x{00e9}l\x{00e8}ve";	# élève — 5 grapheme clusters
	my $gcstr = Unicode::GCString->new($str);
	is($gcstr->length, 5, 'GCString reports 5 for "élève"');
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 5, max => 5 } },
		input  => { s => $str },
	);
	is($r->{s}, $str, '"élève" accepted with min=>5,max=>5');
};

subtest 'Unicode::GCString: mixed ASCII and non-ASCII' => sub {
	my $str = "caf\x{00e9}";	# café — 4 grapheme clusters, 5 bytes
	my $gcstr = Unicode::GCString->new($str);
	is($gcstr->length, 4, 'GCString reports 4 for "café"');
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 4, max => 4 } },
		input  => { s => $str },
	);
	is($r->{s}, $str, '"café" accepted with min=>4,max=>4');
};

# ══════════════════════════════════════════════════════════════════════════════
# Encode integration — UTF-8 byte strings vs character strings
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Encode: UTF-8 byte string decoded and counted by characters' => sub {
	# Produce a byte string (utf8 flag NOT set) from "élève"
	my $bytes = encode('UTF-8', "\x{00e9}l\x{00e8}ve");
	ok(!utf8::is_utf8($bytes), 'byte string does not have the utf8 flag');
	cmp_ok(length($bytes), '==', 7, 'byte length is 7 (2+1+2+1+1)');

	# validate_strict must decode and count as 5 characters, not 7 bytes
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 5, max => 5 } },
		input  => { s => $bytes },
	);
	ok(defined $r->{s}, 'byte-string accepted: character count (5) satisfies min=>5,max=>5');
};

subtest 'Encode: character string with utf8 flag skips decode_utf8' => sub {
	# Characters above U+00FF require internal UTF-8 storage in every Perl
	# version, so utf8::is_utf8 reliably returns true for them.
	my $chars = "\x{65e5}\x{672c}";	# 日本 — two characters, both above U+00FF
	ok(utf8::is_utf8($chars), 'character string with codepoints > U+00FF has utf8 flag');
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 2, max => 2 } },
		input  => { s => $chars },
	);
	is($r->{s}, $chars, 'character string validated by grapheme count, not bytes');
};

# ══════════════════════════════════════════════════════════════════════════════
# Carp integration — croak is catchable; error content is correct
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Carp::croak: validation failure is catchable with eval' => sub {
	eval {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => 'not_a_number' },
		)
	};
	like($@, qr/must be an integer/, 'croak caught by eval; message correct');
};

subtest 'Carp::croak: message includes package name' => sub {
	eval {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => 'bad' },
		)
	};
	like($@, qr/Params::Validate::Strict/, 'error message includes module name');
};

subtest 'Carp::carp: unknown-param warning is catchable via $SIG{__WARN__}' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	validate_strict(
		schema                    => { name => { type => 'string' } },
		input                     => { name => 'Alice', extra => 'x' },
		unknown_parameter_handler => 'warn',
	);
	ok(scalar @warnings > 0, 'carp warning captured via $SIG{__WARN__}');
	like($warnings[0], qr/Unknown parameter/, 'carp message is informative');
};

# ══════════════════════════════════════════════════════════════════════════════
# Statefulness — schema reuse, immutability of inputs, closures
# ══════════════════════════════════════════════════════════════════════════════

subtest 'stateful: same schema validates multiple inputs correctly' => sub {
	my $schema = {
		name  => { type => 'string', min => 2 },
		score => { type => 'integer', min => 0, max => 100 },
	};

	for my $pair (['Alice', 90], ['Bob', 55], ['Carol', 100]) {
		my ($name, $score) = @$pair;
		my $r = validate_strict(
			schema => $schema,
			input  => { name => $name, score => "$score" },
		);
		is($r->{name},  $name,  "reused schema: name '$name' correct");
		is($r->{score}, $score, "reused schema: score $score coerced correctly");
	}
};

subtest 'stateful: validate_strict does not mutate the schema' => sub {
	my $schema = { count => { type => 'integer', min => 1 } };
	my $before  = { count => { type => 'integer', min => 1 } };

	validate_strict(schema => $schema, input => { count => '5' });
	is_deeply($schema, $before, 'schema hashref unchanged after validate_strict');
};

subtest 'stateful: validate_strict does not mutate the input' => sub {
	my $input = { age => '42', name => 'Alice' };
	my $r = validate_strict(
		schema => { age => { type => 'integer' }, name => { type => 'string' } },
		input  => $input,
	);
	is($input->{age},  '42',   'input->{age} still a string after validation');
	is($r->{age},      42,     'return value has coerced integer');
};

subtest 'stateful: closure in callback captures external variable at call time' => sub {
	my $limit = 100;
	my $schema = { n => {
		type     => 'integer',
		callback => sub { $_[0] <= $limit },
	} };

	my $r = validate_strict(schema => $schema, input => { n => 50 });
	is($r->{n}, 50, 'value 50 passes when limit is 100');

	$limit = 10;	# change the captured variable
	throws_ok {
		validate_strict(schema => $schema, input => { n => 50 })
	} qr/failed custom validation/,
	  'value 50 fails after limit reduced to 10 — closure sees updated value';
};

subtest 'stateful: optional coderef re-evaluated on every call' => sub {
	my $make_optional = 0;
	my $schema = {
		required_sometimes => {
			type     => 'string',
			optional => sub { $make_optional },
		},
	};

	throws_ok {
		validate_strict(schema => $schema, input => {})
	} qr/Required parameter/, 'param required when $make_optional is false';

	$make_optional = 1;
	lives_ok {
		validate_strict(schema => $schema, input => {})
	} 'param optional when $make_optional is true';
};

subtest 'stateful: default values from _apply_nested_defaults persist across calls' => sub {
	my $schema = {
		settings => {
			type   => 'hashref',
			schema => {
				theme   => { type => 'string', optional => 1, default => 'light' },
				lang    => { type => 'string', optional => 1, default => 'en' },
			},
		},
	};

	# _apply_nested_defaults only runs when the inner hashref has ≥ 1 key
	# (the module checks scalar keys(%{$value}) before recursing).
	my $r1 = validate_strict(schema => $schema, input => { settings => { theme => 'light' } });
	my $r2 = validate_strict(schema => $schema, input => { settings => { theme => 'dark' } });

	is($r1->{settings}{theme}, 'light', 'first call: supplied theme returned');
	is($r1->{settings}{lang},  'en',    'first call: default lang applied');
	is($r2->{settings}{theme}, 'dark',  'second call: supplied theme returned');
	is($r2->{settings}{lang},  'en',    'second call: default lang still applied');
};

# ══════════════════════════════════════════════════════════════════════════════
# Feature combinations — multiple schema rules working together
# ══════════════════════════════════════════════════════════════════════════════

subtest 'combination: transform + matches + notmemberof together' => sub {
	my $schema = {
		user => {
			type        => 'string',
			transform   => sub { lc $_[0] },	# normalise first
			matches     => qr/^[a-z0-9_]+$/,	# then pattern check
			notmemberof => [qw(admin root system)],	# then blacklist check
			min         => 3,
			max         => 20,
		},
	};

	my $r = validate_strict(schema => $schema, input => { user => 'Alice_99' });
	is($r->{user}, 'alice_99', 'transform + matches + notmemberof: accepted and normalised');

	throws_ok {
		validate_strict(schema => $schema, input => { user => 'ADMIN' })
	} qr/must not be one of/, 'transform lowercased ADMIN → admin, then blacklisted';
};

subtest 'combination: optional coderef depends on another field value' => sub {
	my $schema = {
		method   => { type => 'string', memberof => [qw(GET POST)] },
		body     => {
			type     => 'hashref',
			optional => sub { my ($v, $all) = @_; $all->{method} eq 'GET' },
		},
	};

	# GET → body is optional
	lives_ok {
		validate_strict(schema => $schema, input => { method => 'GET' })
	} 'body optional for GET request';

	# POST → body is required
	throws_ok {
		validate_strict(schema => $schema, input => { method => 'POST' })
	} qr/Required parameter 'body' is missing/, 'body required for POST request';
};

subtest 'combination: nested schema + cross_validation' => sub {
	my $schema = {
		dates => {
			type   => 'hashref',
			schema => {
				start => { type => 'string', matches => qr/^\d{4}-\d{2}-\d{2}$/ },
				end   => { type => 'string', matches => qr/^\d{4}-\d{2}-\d{2}$/ },
			},
		},
	};
	my $xv = {
		order => sub {
			my $p = shift;
			return $p->{dates}{start} le $p->{dates}{end}
				? undef : 'start must be before end';
		},
	};

	lives_ok {
		validate_strict(schema => $schema, input => { dates => { start => '2025-01-01', end => '2025-12-31' } }, cross_validation => $xv)
	} 'nested schema + cross_validation: valid date range accepted';

	throws_ok {
		validate_strict(schema => $schema, input => { dates => { start => '2025-12-31', end => '2025-01-01' } }, cross_validation => $xv)
	} qr/start must be before end/, 'cross_validation catches reversed date range';
};

subtest 'combination: isa check correctly identifies wrong class' => sub {
	# Plain type => 'object' + isa: the isa check runs in the rule loop and
	# produces a specific "must be a '...' object" message.
	# (Using type => ['object'] — a single-element union — would instead
	# produce the array-level "must be one of object" message when isa fails.)
	my $schema = { svc => { type => 'object', isa => 'Int::User', can => 'greet' } };

	lives_ok {
		validate_strict(schema => $schema, input => { svc => $user })
	} 'Int::User with greet method satisfies isa + can';

	# Int::AdminUser inherits from Int::User → isa passes; can => greet also passes
	lives_ok {
		validate_strict(schema => $schema, input => { svc => $admin })
	} 'Int::AdminUser (subclass) also satisfies isa + can';

	# Int::GedcomFile has no greet method and is not an Int::User.
	# Hash key iteration order determines whether isa or can fires first;
	# accept either error message to keep the test deterministic.
	throws_ok {
		validate_strict(schema => $schema, input => { svc => $gedcom })
	} qr/must be a 'Int::User' object|must be an object that understands the greet method/,
	  'Int::GedcomFile fails isa or can check (whichever iterates first)';
};

subtest 'combination: custom_type + transform + callback' => sub {
	my $custom_types = {
		trimmed_string => { type => 'string', min => 1 },
	};
	my $schema = {
		tag => {
			type      => 'trimmed_string',
			transform => sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; $s },
			callback  => sub { $_[0] !~ /[<>]/ },	# no HTML
		},
	};

	my $r = validate_strict(schema => $schema, input => { tag => '  hello world  ' }, custom_types => $custom_types);
	is($r->{tag}, 'hello world', 'transform trimmed whitespace; custom_type and callback passed');

	throws_ok {
		validate_strict(schema => $schema, input => { tag => '<script>' }, custom_types => $custom_types)
	} qr/failed custom validation/, 'callback rejects HTML characters';
};

subtest 'combination: relationships + cross_validation run in correct order' => sub {
	# Relationships are checked before cross_validation.
	# If a relationship fails, cross_validation is never reached.
	my $schema = {
		file    => { type => 'string', optional => 1 },
		content => { type => 'string', optional => 1 },
	};
	my $relationships = [
		{ type => 'mutually_exclusive', params => ['file', 'content'] }
	];
	my $cross_validation = {
		must_have_one => sub {
			my $p = shift;
			return (exists $p->{file} || exists $p->{content})
				? undef : 'Must supply file or content';
		},
	};

	# Both → relationship fails first
	throws_ok {
		validate_strict(
			schema           => $schema,
			input            => { file => 'x.txt', content => 'raw' },
			relationships    => $relationships,
			cross_validation => $cross_validation,
		)
	} qr/Cannot specify both/, 'relationship error raised before cross_validation runs';

	# One → ok for relationship, ok for cross_validation
	lives_ok {
		validate_strict(
			schema           => $schema,
			input            => { file => 'x.txt' },
			relationships    => $relationships,
			cross_validation => $cross_validation,
		)
	} 'single param: relationship and cross_validation both pass';
};

# ══════════════════════════════════════════════════════════════════════════════
# minimum alias and other lesser-used code paths
# ══════════════════════════════════════════════════════════════════════════════

subtest 'minimum: alias for min accepted' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', minimum => 10 } },
			input  => { n => 5 },
		)
	} qr/must be at least 10/, 'minimum alias behaves like min';
};

subtest 'explicit array-of-rules (not union shorthand): first match used' => sub {
	my $r = validate_strict(
		schema => { id => [
			{ type => 'string',  min => 3 },	# name-like string
			{ type => 'integer', min => 1 },	# numeric ID
		] },
		input => { id => 42 },
	);
	is($r->{id}, 42, 'integer branch matched in explicit array-of-rules');
};

subtest 'semantic rule: unix_timestamp valid value accepted' => sub {
	lives_ok {
		validate_strict(
			schema => { ts => { type => 'integer', semantic => 'unix_timestamp' } },
			input  => { ts => 1_700_000_000 },
		)
	} 'valid unix timestamp passes semantic check';
};

subtest 'semantic rule: unknown semantic emits warning but does not croak' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok {
		validate_strict(
			schema => { ts => { type => 'integer', semantic => 'future_type' } },
			input  => { ts => 42 },
		)
	} 'unknown semantic does not croak';
	ok(scalar @warnings > 0, 'unknown semantic emits a warning');
};

subtest 'nullable: absent param omitted from result; present param validated and returned' => sub {
	# nullable => 1 sets $is_optional before the rule-dispatch loop.
	# The loop has an elsif for nullable so it is silently skipped when a
	# value is present — both paths must work correctly.
	my $r_absent = validate_strict(
		schema => { x => { type => 'string', nullable => 1 } },
		input  => {},
	);
	ok(!exists $r_absent->{x}, 'nullable: absent param correctly omitted from result');

	my $r_present = validate_strict(
		schema => { x => { type => 'string', nullable => 1 } },
		input  => { x => 'hello' },
	);
	is($r_present->{x}, 'hello', 'nullable: present param validated and returned');
};

subtest 'position: mixed schema without position sets non-positional mode' => sub {
	# A schema where only SOME keys have position should detect as non-positional
	# (the first key without position sets are_positional_args = 0)
	my $r = validate_strict(
		schema => {
			name => { type => 'string' },		# no position
			age  => { type => 'integer' },		# no position
		},
		input => { name => 'Alice', age => '30' },
	);
	is(ref($r), 'HASH', 'non-positional schema returns hashref');
	is($r->{name}, 'Alice', 'name returned correctly');
};

subtest '_apply_nested_defaults: defaults in arrayref schema element' => sub {
	# nested arrayref schema elements don't apply defaults (only hashref does)
	# but nested hashref schema does
	my $r = validate_strict(
		schema => {
			config => {
				type   => 'hashref',
				schema => {
					timeout => { type => 'integer', optional => 1, default => 30 },
					retries => { type => 'integer', optional => 1, default => 3  },
				},
			},
		},
		input => { config => {} },
	);
	is($r->{config}{timeout}, 30, 'nested default timeout applied');
	is($r->{config}{retries},  3, 'nested default retries applied');
};

# ══════════════════════════════════════════════════════════════════════════════
# Real-world scenario 1: user registration form
# ══════════════════════════════════════════════════════════════════════════════

my $registration_schema = {
	username => {
		type      => 'string',
		min       => 3,
		max       => 20,
		matches   => qr/^[a-z0-9_]+$/,
		transform => sub { lc $_[0] },
	},
	email => {
		type    => 'string',
		matches => qr/^[\w.+-]+\@[\w.-]+\.\w+$/,
	},
	password => {
		type => 'string',
		min  => 8,
	},
	confirm => {
		type => 'string',
	},
	age => {
		type     => 'integer',
		min      => 13,
		max      => 150,
		optional => 1,
	},
	role => {
		type     => 'string',
		memberof => [qw(admin user guest)],
		optional => 1,
		default  => 'user',
	},
};

my $registration_xv = {
	passwords_match => sub {
		my $p = shift;
		$p->{password} eq $p->{confirm} ? undef : "Passwords do not match";
	},
};

subtest 'scenario registration: valid submission accepted' => sub {
	my $r = validate_strict(
		schema           => $registration_schema,
		input            => {
			username => 'Alice_99',
			email    => 'alice@example.com',
			password => 'S3cr3tPwd!',
			confirm  => 'S3cr3tPwd!',
			age      => '28',
		},
		cross_validation => $registration_xv,
	);
	is($r->{username}, 'alice_99', 'username lowercased by transform');
	is($r->{role},     'user',     'default role applied');
	is($r->{age},      28,         'age coerced to integer');
};

subtest 'scenario registration: mismatched passwords rejected' => sub {
	throws_ok {
		validate_strict(
			schema           => $registration_schema,
			input            => {
				username => 'bob',
				email    => 'bob@example.com',
				password => 'abc12345',
				confirm  => 'abc12346',
			},
			cross_validation => $registration_xv,
		)
	} qr/Passwords do not match/, 'cross_validation catches mismatched passwords';
};

subtest 'scenario registration: invalid username pattern rejected' => sub {
	throws_ok {
		validate_strict(
			schema => $registration_schema,
			input  => {
				username => 'bad user!',
				email    => 'x@y.com',
				password => 'goodpassword',
				confirm  => 'goodpassword',
			},
			cross_validation => $registration_xv,
		)
	} qr/must match pattern/, 'username with spaces/special chars rejected';
};

# ══════════════════════════════════════════════════════════════════════════════
# Real-world scenario 2: database connection config
# ══════════════════════════════════════════════════════════════════════════════

my $db_schema = {
	host     => { type => 'string' },
	port     => { type => 'integer', min => 1,  max => 65535 },
	database => { type => 'string' },
	username => { type => 'string' },
	password => { type => 'string' },
	ssl      => { type => 'boolean', optional => 1, default => 0 },	# 0 not 'false': defaults bypass coercion
	timeout  => { type => 'integer', optional => 1, default => 30, minimum => 1 },
};

my $db_relationships = [
	{
		type     => 'value_constraint',
		if       => 'ssl',
		then     => 'port',
		operator => '==',
		value    => 5432,
		description => 'SSL connections must use port 5432',
	},
];

subtest 'scenario db config: standard connection accepted' => sub {
	my $r = validate_strict(
		schema => $db_schema,
		input  => {
			host     => 'db.example.com',
			port     => '5432',
			database => 'myapp',
			username => 'appuser',
			password => 's3cr3t',
		},
	);
	is($r->{host},    'db.example.com', 'host returned');
	is($r->{port},     5432,            'port coerced to integer');
	ok(!$r->{ssl},                      'ssl defaults to false');
	is($r->{timeout},  30,              'timeout defaults to 30');
};

subtest 'scenario db config: port out of range rejected' => sub {
	throws_ok {
		validate_strict(
			schema => $db_schema,
			input  => {
				host => 'x', port => '99999', database => 'd',
				username => 'u', password => 'p',
			},
		)
	} qr/must be no more than 65535/, 'port > 65535 rejected';
};

subtest 'scenario db config: ssl relationship enforced' => sub {
	throws_ok {
		validate_strict(
			schema        => $db_schema,
			input         => {
				host => 'x', port => '3306', database => 'd',
				username => 'u', password => 'p', ssl => 'true',
			},
			relationships => $db_relationships,
		)
	} qr/SSL connections must use port 5432/, 'SSL on wrong port rejected';
};

# ══════════════════════════════════════════════════════════════════════════════
# Real-world scenario 3: genealogy tool parameters (Nigel's domain)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'scenario genealogy: geolocation parameters validated' => sub {
	my $r = validate_strict(
		schema => {
			latitude  => { type => 'number', min => -90,  max => 90  },
			longitude => { type => 'number', min => -180, max => 180 },
			place     => { type => 'string', optional => 1 },
		},
		input => {
			latitude  => '51.5074',
			longitude => '-0.1278',
			place     => 'London',
		},
	);
	ok(abs($r->{latitude}  - 51.5074) < 1e-4, 'latitude coerced correctly');
	ok(abs($r->{longitude} - (-0.1278)) < 1e-4, 'longitude coerced correctly');
	is($r->{place}, 'London', 'place name preserved');
};

subtest 'scenario genealogy: gedcom object integration with can check' => sub {
	my $r = validate_strict(
		schema => {
			gedcom => {
				type     => 'object',
				can      => ['get_individual', 'get_family'],
				optional => 1,
			},
			name => { type => 'string' },
		},
		input => { name => 'Smith', gedcom => $gedcom },
	);
	is($r->{gedcom}, $gedcom, 'Int::GedcomFile accepted via can check');
	is($r->{name},   'Smith', 'name returned alongside object');
};

subtest 'scenario genealogy: absent optional gedcom ok' => sub {
	my $r = validate_strict(
		schema => {
			gedcom => { type => 'object', can => 'get_individual', optional => 1 },
			name   => { type => 'string' },
		},
		input => { name => 'Jones' },
	);
	ok(!exists $r->{gedcom}, 'absent optional gedcom not in result');
};

# ══════════════════════════════════════════════════════════════════════════════
# Data::Processor compatibility — schema wrapping with members/description
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Data::Processor compat: members + description unwrapped transparently' => sub {
	my $r = validate_strict(
		schema => {
			description => 'Application config',
			members     => {
				host => { type => 'string' },
				port => { type => 'integer', min => 1 },
			},
		},
		input => { host => 'localhost', port => '8080' },
	);
	is($r->{host}, 'localhost', 'host returned after members unwrapping');
	is($r->{port},  8080,       'port coerced inside unwrapped members schema');
};

subtest 'Data::Processor compat: error_msg from schema used in failure' => sub {
	throws_ok {
		validate_strict(
			schema => {
				description => 'Widget schema',
				error_msg   => 'Widget validation error',
				members     => { count => { type => 'integer', min => 1 } },
			},
			input => { count => 0 },
		)
	} qr/must be at least|Widget validation error/,
	  'error from members schema reported with context';
};

done_testing;
