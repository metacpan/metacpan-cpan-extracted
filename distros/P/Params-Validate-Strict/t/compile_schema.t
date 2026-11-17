#!/usr/bin/env perl

# compile_schema precompiles a schema so that simple fields skip the generic rule
# interpreter in validate_strict.  The contract is that this is purely an
# optimisation: the result, the error raised, the warnings and the logger calls
# must be exactly what validate_strict(schema => ..., input => ...) gives.
#
# So most of this file is differential: the same schema and input are run through
# both routes and the outcomes compared.  Eligibility is also checked directly,
# so that the comparison cannot pass merely because nothing was compiled.

use strict;
use warnings;
use Test::Most;

use Data::Dumper;
use lib 't/lib';
use Test::Logger;

use Params::Validate::Strict qw(validate_strict compile_schema);

{
	package Local::Foo;
	sub new { bless {}, shift }
}

# ── helpers ──────────────────────────────────────────────────────────────────

# Line numbers differ between the two routes (and between call sites), so they
# are masked; everything else in a message must match.
sub norm
{
	my $s = shift;
	$s =~ s/line \d+/line N/g;
	$s =~ s/0x[0-9a-f]+/0xADDR/g;	# memory addresses differ between runs
	# When both min and max are meaningless for a type, which is reported first
	# depends on hash order (it always has), so the two are treated as the same.
	$s =~ s/meaningless (?:min|max) value \S+/meaningless bound/g;
	$s =~ s/\s+\z//;
	return $s;
}

# Run $code, capturing result, error and warnings in a comparable form
sub outcome
{
	my $code = shift;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, norm($_[0]) };
	my $result;
	my $ok = eval { $result = $code->(); 1 };
	my $error = $ok ? undef : norm("$@");
	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Useqq = 1;
	return norm(Dumper([ $ok ? 1 : 0, $error, $result, \@warnings ]));
}

sub fields_of
{
	my $compiled = Params::Validate::Strict::_compile_schema(@_);
	return $compiled ? $compiled->{'fields'} : undef;
}

# ── what is, and is not, compiled ────────────────────────────────────────────

subtest 'eligible fields are compiled' => sub {
	my @eligible = (
		'a plain type string'       => { a => 'string' },
		'type with no other rules'  => { a => { type => 'integer' } },
		'min and max on string'     => { a => { type => 'string', min => 1, max => 5 } },
		'min and max on integer'    => { a => { type => 'integer', min => 0, max => 5 } },
		'min and max on number'     => { a => { type => 'number', min => 0.5, max => 5 } },
		'min and max on float'      => { a => { type => 'float', min => 0, max => 5 } },
		'min and max on arrayref'   => { a => { type => 'arrayref', min => 1, max => 5 } },
		'min and max on hashref'    => { a => { type => 'hashref', min => 1, max => 5 } },
		'optional'                  => { a => { type => 'string', optional => 1 } },
		'optional => 0'             => { a => { type => 'string', optional => 0 } },
		'nullable'                  => { a => { type => 'string', nullable => 1 } },
		'optional with default'     => { a => { type => 'string', optional => 1, default => 'x' } },
		'matches with a regex'      => { a => { type => 'string', matches => qr/^a/ } },
		'matches with a string'     => { a => { type => 'string', matches => 'a.b' } },
		'memberof'                  => { a => { type => 'string', memberof => ['x', 'y'] } },
		'enum'                      => { a => { type => 'string', enum => ['x', 'y'] } },
		'values'                    => { a => { type => 'string', values => ['x', 'y'] } },
		'memberof, case insensitive' => { a => { type => 'string', memberof => ['x'], case_sensitive => 0 } },
		'description'               => { a => { type => 'string', description => 'a thing' } },
		'error_msg'                 => { a => { type => 'string', error_msg => 'bad' } },
		'mixed-case type name'      => { a => { type => 'String', min => 1 } },
		'boolean'                   => { a => { type => 'boolean' } },
		'scalar'                    => { a => { type => 'scalar' } },
		'coderef'                   => { a => { type => 'coderef' } },
		'object'                    => { a => { type => 'object' } },
	);
	while(my ($name, $schema) = splice(@eligible, 0, 2)) {
		my $fields = fields_of($schema);
		ok($fields && $fields->{'a'}, "compiled: $name");
	}
};

subtest 'ineligible fields are left to the generic code' => sub {
	my @ineligible = (
		'callback'                  => { a => { type => 'string', callback => sub { 1 } } },
		'validate'                  => { a => { type => 'string', validate => sub { 0 } } },
		'transform'                 => { a => { type => 'string', transform => sub { $_[0] } } },
		'optional as a coderef'     => { a => { type => 'string', optional => sub { 1 } } },
		'union by pipe'             => { a => { type => 'string|integer' } },
		'union by arrayref'         => { a => { type => ['string', 'integer'] } },
		'aliases'                   => { a => { type => 'string', aliases => ['b'] } },
		'needs'                     => { a => { type => 'string', needs => 'b' }, b => 'string' },
		'nested schema'             => { a => { type => 'hashref', schema => { x => 'string' } } },
		'element_type'              => { a => { type => 'arrayref', element_type => 'string' } },
		'nomatch'                   => { a => { type => 'string', nomatch => 'x' } },
		'notmemberof'               => { a => { type => 'string', notmemberof => ['x'] } },
		'isa'                       => { a => { type => 'object', isa => 'Local::Foo' } },
		'semantic'                  => { a => { type => 'string', semantic => 'identifier' } },
		'an unknown rule'           => { a => { type => 'string', frobnicate => 1 } },
		'an internal _ rule'        => { a => { type => 'string', _note => 1 } },
		'min on int (an error)'     => { a => { type => 'int', min => 1 } },
		'min on boolean (an error)' => { a => { type => 'boolean', min => 1 } },
		'min on scalar (an error)'  => { a => { type => 'scalar', max => 1 } },
		'min below zero on string'  => { a => { type => 'string', min => -1 } },
		'min greater than max'      => { a => { type => 'integer', min => 5, max => 1 } },
		'non-numeric min'           => { a => { type => 'string', min => 'x' } },
		'undefined min'             => { a => { type => 'string', min => undef } },
		'memberof with min'         => { a => { type => 'string', memberof => ['x'], min => 1 } },
		'memberof with max'         => { a => { type => 'string', memberof => ['x'], max => 1 } },
		'memberof and enum'         => { a => { type => 'string', memberof => ['x'], enum => ['y'] } },
		'memberof not an arrayref'  => { a => { type => 'string', memberof => 'x' } },
		'case_sensitive on its own' => { a => { type => 'string', case_sensitive => 0 } },
		'matches on an arrayref'    => { a => { type => 'arrayref', matches => qr/x/ } },
		'matches an arrayref'       => { a => { type => 'string', matches => ['x'] } },
		'no type'                   => { a => { min => 1 } },
		'undef type'                => { a => { type => undef } },
		'stringref'                 => { a => { type => 'stringref' } },
		'void'                      => { a => { type => 'void' } },
		'regex type'                => { a => { type => 'regex' } },
		'handle'                    => { a => { type => 'handle' } },
		'unknown type'              => { a => 'frobnicate' },
		'description undefined'     => { a => { type => 'string', description => undef } },
		'a blessed rule value'      => { a => { type => 'string', min => bless({}, 'Local::Foo') } },
		'undefined rules (anything)' => { a => undef },
	);
	while(my ($name, $schema) = splice(@ineligible, 0, 2)) {
		my $fields = fields_of($schema);
		ok(!($fields && $fields->{'a'}), "not compiled: $name");
	}

	ok(!fields_of({ a => { type => 'string' } }, { string => { type => 'string' } })->{'a'},
		'a custom type shadowing a built-in name is not compiled');
	ok(fields_of({ a => { type => 'string' } }, { other => { type => 'string' } })->{'a'},
		'an unrelated custom type does not prevent compilation');
};

subtest 'whole schemas that are not compiled' => sub {
	ok(!defined(Params::Validate::Strict::_compile_schema({ a => { type => 'string', position => 0 } })),
		'a positional schema');
	ok(!defined(Params::Validate::Strict::_compile_schema({ a => { type => 'arrayref', slurp => 1 } })),
		'a slurp schema');
	ok(!defined(Params::Validate::Strict::_compile_schema({ members => { a => 'string' }, description => 'x' })),
		'a members wrapper');
	ok(!defined(Params::Validate::Strict::_compile_schema([ { name => 'a', type => 'string' } ])),
		'an arrayref (normalised before compiling)');
	ok(defined(Params::Validate::Strict::_compile_schema({})), 'an empty schema is compiled');
};

subtest 'schema-level facts' => sub {
	my $c = Params::Validate::Strict::_compile_schema({ a => 'string' });
	is($c->{'has_aliases'}, 0, 'no aliases');
	is($c->{'has_needs'}, 0, 'no needs');
	$c = Params::Validate::Strict::_compile_schema({ a => { type => 'string', aliases => ['b'] }, c => 'string' });
	is($c->{'has_aliases'}, 1, 'aliases noticed');
	$c = Params::Validate::Strict::_compile_schema({ a => { type => 'string', needs => 'c' }, c => 'string' });
	is($c->{'has_needs'}, 1, 'needs noticed');
};

# ── the differential matrix ──────────────────────────────────────────────────
#
# Every type crossed with every rule variant (valid and invalid), crossed with a
# spread of inputs including absent and undef.  One compiled validator per
# (type, variant) is reused for all its inputs.

my @types = qw(string str integer int number float num double boolean bool
	arrayref hashref scalar coderef object String Integer ArrayRef);

# A function, so that each route gets its own copy of the data: the memberof
# lookup cache is keyed by list address, so sharing a list would make whichever
# route ran second silently skip work (and the warnings that go with it).
sub variants
{
	return (
	{},
	{ optional => 1 }, { optional => 0 }, { nullable => 1 },
	{ optional => 1, default => 'dflt' }, { default => 'dflt' },
	{ optional => 0, nullable => 1 },
	{ min => 1 }, { max => 3 }, { min => 1, max => 3 }, { min => 0 }, { min => 2, max => 2 },
	{ min => '1' }, { min => 0.5 }, { min => 1, optional => 1 }, { max => 2, nullable => 1 },
	{ matches => qr/^a/ }, { matches => 'a.b' }, { matches => qr/^\d+$/, optional => 1 },
	{ memberof => ['abc', 'a.b', '5', '1'] }, { enum => ['abc', '5'] }, { values => ['1', '5'] },
	{ memberof => ['ABC', 'A.B'], case_sensitive => 0 }, { memberof => ['abc'], case_sensitive => 1 },
	{ description => 'a thing' }, { error_msg => 'custom message' },
	{ description => 'd', error_msg => 'custom', min => 1 },
	{ description => 'd', optional => 1, max => 3 },
	# rules that must be reported identically however they are handled
	{ min => 5, max => 1 }, { min => -1 }, { min => 'x' }, { min => undef },
	{ memberof => ['a'], min => 1 }, { memberof => 'a' }, { matches => [1] },
	{ unknown_rule => 1 }, { transform => sub { defined $_[0] ? "$_[0]" : $_[0] } },
	{ callback => sub { 1 } }, { callback => sub { 0 } }, { optional => sub { 1 } },
	{ needs => ['other'] }, { case_sensitive => 0 }, { nomatch => 'zq' }, { notmemberof => ['a'] },
	);
}

my $code = sub { 1 };
my $obj = Local::Foo->new;
my %inputs = (
	'absent'      => sub { {} },
	'undef'       => sub { { a => undef } },
	'empty'       => sub { { a => '' } },
	'a'           => sub { { a => 'a' } },
	'abc'         => sub { { a => 'abc' } },
	'a.b'         => sub { { a => 'a.b' } },
	'A.B'         => sub { { a => 'A.B' } },
	'long'        => sub { { a => 'abcdefghij' } },
	'zero'        => sub { { a => 0 } },
	'one'         => sub { { a => 1 } },
	'minus one'   => sub { { a => -1 } },
	'five'        => sub { { a => 5 } },
	'"5"'         => sub { { a => '5' } },
	'42.0'        => sub { { a => '42.0' } },
	'3.14'        => sub { { a => 3.14 } },
	'1e3'         => sub { { a => '1e3' } },
	'Inf'         => sub { { a => 'Inf' } },
	'yes'         => sub { { a => 'yes' } },
	'false'       => sub { { a => 'false' } },
	'unicode'     => sub { { a => "caf\x{e9}\x{263a}" } },
	'empty array' => sub { { a => [] } },
	'array of 4'  => sub { { a => [1, 2, 3, 4] } },
	'empty hash'  => sub { { a => {} } },
	'hash of 2'   => sub { { a => { x => 1, y => 2 } } },
	'scalar ref'  => sub { { a => \'x' } },
	'coderef'     => sub { { a => $code } },
	'object'      => sub { { a => $obj } },
	'extra key'   => sub { { a => 'abc', zzz => 1 } },
	'only extra'  => sub { { zzz => 1 } },
);

my $combinations = 0;
foreach my $type (@types) {
	subtest "matrix: $type" => sub {
		my @mismatch;
		my @for_generic = variants();
		my @for_compiled = variants();
		foreach my $i (0 .. $#for_generic) {
			my $generic_schema = { a => { type => $type, %{$for_generic[$i]} } };
			my $compiled_schema = { a => { type => $type, %{$for_compiled[$i]} } };
			my $validator = compile_schema($compiled_schema);
			my $desc = Data::Dumper->new([$for_generic[$i]])->Terse(1)->Indent(0)->Sortkeys(1)->Deparse(0)->Dump;
			foreach my $name (sort keys %inputs) {
				$combinations++;
				my $generic  = outcome(sub { validate_strict(schema => $generic_schema, input => $inputs{$name}->()) });
				my $compiled = outcome(sub { $validator->($inputs{$name}->()) });
				push @mismatch, "variant $desc, input '$name':\n  generic:  $generic\n  compiled: $compiled"
					if($generic ne $compiled);
			}
		}
		is(scalar(@mismatch), 0, "type '$type': compiled and generic agree for every rule variant and input")
			or diag(join("\n", @mismatch[0 .. ($#mismatch < 4 ? $#mismatch : 4)]));
	};
}
cmp_ok($combinations, '>', 20000, "the matrix exercised $combinations combinations");

# ── schemas with several fields, mixing compiled and generic ─────────────────

subtest 'mixed schemas agree' => sub {
	# Each schema is paired with its own inputs, so that at most one unknown key
	# is ever present: which of several is reported first depends on hash order.
	my @cases = (
		[
			{
				name => { type => 'string', min => 1, max => 50 },
				age => { type => 'integer', min => 0, max => 150 },
				email => { type => 'string', matches => qr/@/ },
				tags => { type => 'arrayref', optional => 1 },
				active => { type => 'boolean', optional => 1, default => 0 },
			},
			{},
			{ name => 'Alice', age => 30, email => 'a@b.c' },
			{ name => 'Alice', age => 30, email => 'a@b.c', tags => [1], active => 'yes' },
			{ name => '', age => 30, email => 'a@b.c' },
			{ name => 'Alice', age => 200, email => 'a@b.c' },
			{ name => 'Alice', age => 'x', email => 'a@b.c' },
			{ name => 'Alice', age => 30, email => 'nope' },
			{ name => 'Alice', age => 30 },
			{ name => 'Alice', age => 30, email => 'a@b.c', extra => 1 },
		],
		[
			{	# compiled fields alongside every kind of generic field
				plain => 'string',
				cb => { type => 'string', callback => sub { $_[0] ne 'bad' } },
				tr => { type => 'string', transform => sub { uc $_[0] } },
				un => 'string|integer',
				ar => { type => ['integer', 'string'] },
				al => { type => 'string', aliases => ['alias_one', 'alias_two'], optional => 1 },
				nd => { type => 'string', optional => 1, needs => ['plain'] },
				ns => { type => 'hashref', optional => 1, schema => { x => { type => 'integer', optional => 1 } } },
				any => undef,
				int => { type => 'integer', min => 0, optional => 1 },
			},
			{ plain => 'p', cb => 'ok', tr => 'x', un => 5, ar => 'z' },
			{ plain => 'p', cb => 'bad', tr => 'x', un => 5, ar => 'z' },
			{ plain => 'p', cb => 'ok', tr => 'x', un => [], ar => 'z' },
			{ plain => 'p', cb => 'ok', tr => 'x', un => 'u', ar => 3, alias_one => 'A', any => 7 },
			{ plain => 'p', cb => 'ok', tr => 'x', un => 'u', ar => 3, alias_two => 'A', nd => 'n', ns => { x => '4' } },
			{ cb => 'ok', tr => 'x', un => 'u', ar => 3, nd => 'n' },
			{ plain => 'p', cb => 'ok', tr => 'x', un => 'u', ar => 3, int => -1 },
			{ plain => 'p', cb => 'ok', tr => 'x', un => 'u', ar => 3, ns => { x => 'no' } },
			{ plain => 'p', cb => 'ok', tr => 'x', un => 'u', ar => 3, unknown1 => 1 },
			{},
		],
		[ { one => 'integer' }, { one => 1 }, { one => '1.5' }, { one => undef }, { one => 3, two => 4 }, {}, { two => 1 } ],
		[ {}, {}, { one => 1 } ],
	);
	my @mismatch;
	my $compared = 0;
	foreach my $handler (undef, 'die', 'warn', 'ignore', 'bogus') {
		my %opts = defined($handler) ? (unknown_parameter_handler => $handler) : ();
		my $n = 0;
		foreach my $case (@cases) {
			my ($schema, @inputs) = @{$case};
			my $validator = compile_schema($schema, %opts);
			foreach my $input (@inputs) {
				$compared++;
				my $generic  = outcome(sub { validate_strict(schema => $schema, input => { %{$input} }, %opts) });
				my $compiled = outcome(sub { $validator->({ %{$input} }) });
				push @mismatch, 'handler ' . ($handler // 'default') . ", schema $n, input " . join(',', sort keys %{$input})
					. "\n  generic:  $generic\n  compiled: $compiled" if($generic ne $compiled);
			}
			$n++;
		}
	}
	cmp_ok($compared, '>', 100, "compared $compared schema/input/handler combinations");
	is(scalar(@mismatch), 0, 'every mixed schema and input agreed')
		or diag(join("\n", @mismatch[0 .. ($#mismatch < 4 ? $#mismatch : 4)]));
};

subtest 'defaults and positional-style outputs agree' => sub {
	my $schema = { a => { type => 'string', optional => 1, default => 'd' }, b => { type => 'integer', optional => 1 } };
	my $validator = compile_schema($schema);
	is_deeply($validator->({}), { a => 'd' }, 'default is filled in for a missing optional');
	is_deeply($validator->({ a => 'x', b => '7.0' }), { a => 'x', b => 7 }, 'integer is coerced');
	is_deeply($validator->({ a => undef }), { a => undef }, 'a present undef is kept, not replaced by the default');
};

# ── options that are forwarded ───────────────────────────────────────────────

subtest 'logger calls agree' => sub {
	my @schemas = (
		{ a => { type => 'integer', min => 0 } },
		{ a => { type => 'string', min => 1 }, b => 'integer' },
		{ a => { type => 'string', matches => qr/^x/ } },
	);
	my @inputs = ({ a => -1 }, { a => '' }, {}, { a => 'y', b => 'z' }, { a => 'x', b => 1 }, { a => 1, zz => 1 });
	foreach my $schema (@schemas) {
		foreach my $input (@inputs) {
			my ($l1, $l2) = (Test::Logger->new, Test::Logger->new);
			my $validator = compile_schema($schema, logger => $l2);
			outcome(sub { validate_strict(schema => $schema, input => { %{$input} }, logger => $l1) });
			outcome(sub { $validator->({ %{$input} }) });
			# The logger gets the message in pieces (package, ' line ', N, ': text'); join them
			# so that norm() can mask the line number as it does for croak messages.
			my $norm = sub { [ map { my ($level, @parts) = @{$_}; [ $level, norm(join('', @parts)) ] } @_ ] };
			is_deeply($norm->($l2->get_messages), $norm->($l1->get_messages),
				'same logger calls for input ' . join(',', map { "$_=" . ($input->{$_} // 'undef') } sort keys %{$input}));
		}
	}
};

subtest 'options are forwarded' => sub {
	my $validator = compile_schema({ a => 'integer' }, description => 'My form');
	throws_ok { $validator->({ a => 'x' }) } qr/My form: Parameter 'a' \(x\) must be an integer/,
		'description appears in a compiled error';
	throws_ok { $validator->({}) } qr/My form: Required parameter 'a' is missing/,
		'description appears in a compiled missing-parameter error';

	$validator = compile_schema({ a => 'integer' }, unknown_parameter_handler => 'ignore');
	lives_ok { $validator->({ a => 1, b => 2 }) } 'unknown_parameter_handler => ignore is honoured';

	$validator = compile_schema({ a => 'integer' }, cross_validation => { never => sub { 'always fails' } });
	throws_ok { $validator->({ a => 1 }) } qr/always fails/, 'cross_validation is honoured';

	$validator = compile_schema({ a => { type => 'string', optional => 1 }, b => { type => 'string', optional => 1 } },
		relationships => [{ type => 'mutually_exclusive', params => ['a', 'b'] }]);
	lives_ok { $validator->({ a => 'x' }) } 'relationships: one parameter passes';
	throws_ok { $validator->({ a => 'x', b => 'y' }) } qr/mutually exclusive|Cannot specify/i,
		'relationships are honoured';

	$validator = compile_schema({ a => { type => 'color' } }, custom_types => { color => { type => 'string', memberof => ['red', 'blue'] } });
	lives_ok { $validator->({ a => 'red' }) } 'custom_types: a valid custom value passes';
	throws_ok { $validator->({ a => 'green' }) } qr/must be one of/, 'custom_types: an invalid custom value fails';
};

subtest 'a custom type that shadows a built-in name still wins' => sub {
	my $types = { string => { type => 'string', memberof => ['only'] } };
	my $schema = { a => 'string' };
	my $validator = compile_schema($schema, custom_types => $types);
	my $generic  = outcome(sub { validate_strict(schema => $schema, input => { a => 'other' }, custom_types => $types) });
	my $compiled = outcome(sub { $validator->({ a => 'other' }) });
	is($compiled, $generic, 'same outcome as the generic route');
};

# ── compile_schema behaviour ─────────────────────────────────────────────────

subtest 'compile_schema behaviour' => sub {
	throws_ok { compile_schema('nope') } qr/schema must be a hash or array reference/, 'a non-ref schema croaks at compile time';
	throws_ok { compile_schema(undef) } qr/schema must be a hash or array reference/, 'an undef schema croaks at compile time';

	# An arrayref schema is normalised once
	my $validator = compile_schema([{ name => 'n', type => 'string', min => 1 }, { name => 'm', type => 'integer', optional => 1 }]);
	is_deeply($validator->({ n => 'x', m => '3' }), { n => 'x', m => 3 }, 'an arrayref schema validates');
	throws_ok { $validator->({ n => '' }) } qr/too short|must be at least 1/, 'an arrayref schema reports errors';

	# A bad arrayref schema is reported when called, as it always was
	lives_ok { $validator = compile_schema([{ type => 'string' }]) } 'a bad arrayref schema does not croak at compile time';
	throws_ok { $validator->({}) } qr/must have a 'name' key/, 'a bad arrayref schema croaks when called';

	# Options that would override schema/input take the original route
	$validator = compile_schema({ a => 'string' }, input => { a => 'fixed' });
	is_deeply($validator->({ a => 'ignored?' }), { a => 'fixed' }, 'an input option wins, exactly as before');

	# The validator is reusable, including after a failure
	$validator = compile_schema({ a => { type => 'integer', min => 1 } });
	throws_ok { $validator->({ a => 0 }) } qr/positive/, 'a failing call dies';
	is_deeply($validator->({ a => 2 }), { a => 2 }, 'the next call is unaffected');
	is_deeply($validator->({ a => 3 }), { a => 3 }, 'and so is the one after');

	# Not stateful across inputs
	my $r1 = $validator->({ a => 5 });
	my $r2 = $validator->({ a => 6 });
	isnt($r1, $r2, 'each call returns a fresh hash');
	is($r1->{'a'}, 5, 'earlier result is not overwritten by a later call');

	# undef / non-hash input is rejected as validate_strict rejects it
	throws_ok { $validator->(undef) } qr/args must be a hash or array reference/, 'undef input is rejected';
	throws_ok { $validator->('x') } qr/args must be a hash or array reference/, 'a non-ref input is rejected';

	# The caller's input is not modified
	my $input = { a => '7.0' };
	$validator->($input);
	is($input->{'a'}, '7.0', 'the input hash is left alone');
};

subtest 're-entrant use' => sub {
	# A callback may itself use the validator that is currently running
	my $inner = compile_schema({ n => { type => 'integer', min => 0 } });
	my $outer;
	$outer = compile_schema({
		x => { type => 'integer' },
		y => { type => 'string', callback => sub { $inner->({ n => 1 }); 1 } },
	});
	is_deeply($outer->({ x => 1, y => 's' }), { x => 1, y => 's' }, 'a validator can be used from inside a callback');

	# A validator calling itself recursively through a callback
	my $depth = 0;
	my $self;
	$self = compile_schema({
		v => { type => 'integer' },
		r => { type => 'string', optional => 1, callback => sub {
			return 1 if(++$depth > 3);
			$self->({ v => $depth, r => 'again' });
			1;
		} },
	});
	is_deeply($self->({ v => 0, r => 'go' }), { v => 0, r => 'go' }, 'a validator can recurse into itself');
	is($depth, 4, 'the recursion happened');
	throws_ok { $self->({ v => 'x' }) } qr/must be an integer/, 'and still validates correctly afterwards';
};

subtest 'the generic route still works for direct calls' => sub {
	# validate_strict called with a hashref argument is not copied; make sure it
	# is neither modified nor confused by being reused.
	my $params = { schema => { a => { type => 'integer', min => 0 } }, input => { a => 1 } };
	is_deeply(validate_strict($params), { a => 1 }, 'a hashref argument works');
	is_deeply($params, { schema => { a => { type => 'integer', min => 0 } }, input => { a => 1 } }, 'and is not modified');
	$params->{'input'} = { a => -1 };
	throws_ok { validate_strict($params) } qr/positive|at least/, 'and may be reused with different input';
};

subtest 'needs is still applied, and in a stable order' => sub {
	my $schema = {
		user => { type => 'string', optional => 1, needs => ['password'] },
		password => { type => 'string', optional => 1 },
	};
	throws_ok { validate_strict(schema => $schema, input => { user => 'u' }) } qr/password/, 'needs: directly';
	throws_ok { compile_schema($schema)->({ user => 'u' }) } qr/password/, 'needs: compiled';
	lives_ok { validate_strict(schema => { a => { type => 'string', optional => 1 } }, input => {}) } 'no needs at all';
};

done_testing();
