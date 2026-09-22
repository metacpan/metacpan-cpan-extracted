#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(refaddr);
use Params::Validate::Strict qw(validate_strict);
use Params::Validate::Strict::BNF qw(bnf_to_matcher);

# ── bnf_to_matcher: unit tests ────────────────────────────────────────────────

subtest 'bnf_to_matcher: single terminal' => sub {
	my $m = bnf_to_matcher(['<word> ::= "hello"']);
	ok($m->('hello'),  'exact match accepted');
	ok(!$m->('world'), 'non-match rejected');
	ok(!$m->(''),      'empty string rejected');
};

subtest 'bnf_to_matcher: alternatives' => sub {
	my $m = bnf_to_matcher(['<answer> ::= "yes" | "no"']);
	ok($m->('yes'),   'first alternative accepted');
	ok($m->('no'),    'second alternative accepted');
	ok(!$m->('maybe'),'non-alternative rejected');
};

subtest 'bnf_to_matcher: empty terminal makes production optional' => sub {
	my $m = bnf_to_matcher(['<sep> ::= "" | "-"']);
	ok($m->(''),  'empty string accepted');
	ok($m->('-'), 'dash accepted');
	ok(!$m->('.'), 'dot rejected');
};

subtest 'bnf_to_matcher: sequence of terminals' => sub {
	my $m = bnf_to_matcher(['<hw> ::= "hello" " " "world"']);
	ok($m->('hello world'),  'full sequence accepted');
	ok(!$m->('hello'),        'partial sequence rejected');
};

subtest 'bnf_to_matcher: nonterminal reference' => sub {
	my $m = bnf_to_matcher([
		'<ab>  ::= <a> <b>',
		'<a>   ::= "a"',
		'<b>   ::= "b"',
	]);
	ok($m->('ab'),  'sequence of nonterminals accepted');
	ok(!$m->('a'),  'partial nonterminal rejected');
	ok(!$m->('ba'), 'wrong order rejected');
};

subtest 'bnf_to_matcher: continuation line' => sub {
	my $m = bnf_to_matcher([
		'<long> ::= "a" "b"',
		'"c" "d"',
	]);
	ok($m->('abcd'),   'continuation line joined to rule');
	ok(!$m->('ab'),    'partial match rejected');
};

subtest 'bnf_to_matcher: anchored — no partial matches' => sub {
	my $m = bnf_to_matcher(['<word> ::= "hi"']);
	ok(!$m->('hi there'), 'trailing text rejected');
	ok(!$m->(' hi'),      'leading text rejected');
};

subtest 'bnf_to_matcher: undef returns 0' => sub {
	my $m = bnf_to_matcher(['<x> ::= "x"']);
	ok(!$m->(undef), 'undef returns false');
};

subtest 'bnf_to_matcher: telephone number grammar' => sub {
	my @grammar = (
		'<telephone-number> ::= <country-code-opt> <area-code> <separator-opt>',
		'<central-office-code> <separator-opt> <station-code>',
		'<country-code-opt>    ::= "" | "+1" | "1"',
		'<separator-opt>       ::= "" | "-" | " " | "."',
		'<area-code>           ::= <digit2-9> <digit0-9> <digit0-9>',
		'<central-office-code> ::= <digit2-9> <digit0-9> <digit0-9>',
		'<station-code>        ::= <digit0-9> <digit0-9> <digit0-9> <digit0-9>',
		'<digit0-9> ::= "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"',
		'<digit2-9> ::= "2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"',
	);
	my $m = bnf_to_matcher(\@grammar);

	ok($m->('2125551234'),    'plain 10-digit accepted');
	ok($m->('+12125551234'),  '+1 prefix accepted');
	ok($m->('12125551234'),   '1 prefix accepted');
	ok($m->('212-555-1234'),  'dash separators accepted');
	ok($m->('212 555 1234'),  'space separators accepted');
	ok($m->('212.555.1234'),  'dot separators accepted');
	ok(!$m->('1234'),         'too short rejected');
	ok(!$m->('02125551234'),  'area code starting with 0 rejected');
	ok(!$m->('212-555-123'),  'station code too short rejected');
};

subtest 'bnf_to_matcher: cache — same grammar compiles once' => sub {
	my @g = ('<x> ::= "x"');
	my $m1 = bnf_to_matcher(\@g);
	my $m2 = bnf_to_matcher(\@g);
	is(refaddr($m1), refaddr($m2), 'same closure returned from cache');
};

subtest 'bnf_to_matcher: error — not an arrayref' => sub {
	throws_ok { bnf_to_matcher('not an arrayref') }
		qr/must be an arrayref/, 'scalar arg croaks';
};

subtest 'bnf_to_matcher: error — empty grammar' => sub {
	throws_ok { bnf_to_matcher([]) }
		qr/at least 1 member/, 'empty arrayref croaks';
};

subtest 'bnf_to_matcher: error — undefined nonterminal' => sub {
	throws_ok { bnf_to_matcher(['<a> ::= <b>']) }
		qr/undefined rule.*<b>/, 'missing rule croaks';
};

subtest 'bnf_to_matcher: error — recursive rule' => sub {
	throws_ok { bnf_to_matcher(['<a> ::= <a> "x"']) }
		qr/recursive rule.*<a>/, 'recursive rule croaks';
};

# ── validate_strict integration ───────────────────────────────────────────────

my @tel_grammar = (
	'<telephone-number> ::= <country-code-opt> <area-code> <separator-opt>',
	'<central-office-code> <separator-opt> <station-code>',
	'<country-code-opt>    ::= "" | "+1" | "1"',
	'<separator-opt>       ::= "" | "-" | " " | "."',
	'<area-code>           ::= <digit2-9> <digit0-9> <digit0-9>',
	'<central-office-code> ::= <digit2-9> <digit0-9> <digit0-9>',
	'<station-code>        ::= <digit0-9> <digit0-9> <digit0-9> <digit0-9>',
	'<digit0-9> ::= "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"',
	'<digit2-9> ::= "2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"',
);

subtest 'validate_strict: bnf — valid telephone number passes' => sub {
	lives_ok {
		validate_strict({
			input  => { phone => '2125551234' },
			schema => { phone => { type => 'string', bnf => \@tel_grammar } },
		});
	} '10-digit number passes';
};

subtest 'validate_strict: bnf — invalid value croaks' => sub {
	throws_ok {
		validate_strict({
			input  => { phone => 'not-a-phone' },
			schema => { phone => { type => 'string', bnf => \@tel_grammar } },
		});
	} qr/does not match the BNF grammar/, 'invalid value croaks with expected message';
};

subtest 'validate_strict: bnf — undef passes (skipped like matches)' => sub {
	lives_ok {
		validate_strict({
			input  => { phone => undef },
			schema => { phone => { type => 'string', bnf => \@tel_grammar, optional => 1 } },
		});
	} 'optional undef passes BNF check';
};

subtest 'validate_strict: bnf — error_msg override' => sub {
	throws_ok {
		validate_strict({
			input  => { phone => 'bad' },
			schema => { phone => {
				type      => 'string',
				bnf       => \@tel_grammar,
				error_msg => 'custom phone error',
			} },
		});
	} qr/custom phone error/, 'error_msg overrides default BNF message';
};

subtest 'validate_strict: bnf — non-arrayref rule croaks' => sub {
	throws_ok {
		validate_strict({
			input  => { x => 'hello' },
			schema => { x => { type => 'string', bnf => 'not an arrayref' } },
		});
	} qr/must be an arrayref/, 'scalar bnf rule croaks';
};

done_testing();
