#!perl

#use Test::Most qw(defer_plan);

use Test::More tests => 207;

use Search::Elasticsearch::Compat::QueryParser;

my $qp = Search::Elasticsearch::Compat::QueryParser->new;

#===================================
# TOKENS
#===================================
tokens( 'Term', 'foo foo\"', qw(_TERM _SPACE _TERM) );
tokens( 'Wildterm', '* ? foo* f?w* ', (qw(_WILDTERM _SPACE)) x 4 );
tokens( 'Phrase', '"foo\""', '_PHRASE' );
tokens(
    'Boolean',
    'AND OR && || ! NOT ',
    (qw(_AND_OR _SPACE)) x 4,
    (qw(_NOT _SPACE)) x 2
);
tokens( 'PlusMinus', '+-', (qw(_PLUS_MINUS)) x 2 );
tokens( 'Group',     '(foo)',     qw(_LPAREN _TERM _RPAREN) );
tokens( 'Modifiers', '^1.1 ~0.1', qw(_BOOST _SPACE _FUZZY) );
tokens( 'Exists', '_exists_:foo _missing_:foo', qw(_EXISTS _SPACE _EXISTS) );
tokens( 'Field', 'foo:bar', qw(_FIELD _TERM) );
tokens( 'Range_in', '[a TO b] [a b]', qw(_RANGE _SPACE _RANGE) );
tokens( 'Range_ex', '{a TO b} {a b}', qw(_RANGE _SPACE _RANGE) );
tokens( 'Reserved', '"&|[]{}:', ('_RESERVED') x 8 );
tokens( 'Escape', 'foo\\', qw(_TERM _ESCAPE) );

#===================================
# Terms
#===================================
test( 'Terms', 'foo bar foo" baz\"', 'foo bar foo baz\\"', 'Reserved' );

#===================================
# Wildcards
#===================================
test( 'Wildcards - 1', 'foo*',  'foo*',  '' );
test( 'Wildcards - 2', 'fo?o*', 'fo?o*', '' );
test( 'Wildcards - 3', '*',     '',      'first character' );
test( 'Wildcards - 4', '*',     '*',     '', wildcard_prefix => 0 );
test(
    'Wildcards - 5',
    'foo* fooo* foo?bar fooo?bar',
    'foo fooo* foo fooo?bar',
    'first 4',
    wildcard_prefix => 4
);

#===================================
# Phrase
#===================================
test( 'Phrase - 1', '"foo bar"baz',   '"foo bar" baz',   '' );
test( 'Phrase - 2', '"foo bar\"baz"', '"foo bar\\"baz"', '' );
test( 'Phrase - 3', '"foo bar',       'foo bar',         'Reserved' );

#===================================
# Boolean
#===================================
test(
    'Boolean - 1',
    'foo AND bar OR baz NOT balloo',
    'foo AND bar OR baz NOT balloo'
);
test(
    'Boolean - 2',
    'foo && bar || baz ! balloo',
    'foo && bar || baz ! balloo'
);
test(
    'Boolean - 3',                'foo&&bar||baz!balloo',
    'foo && bar || baz ! balloo', ''
);
test( 'Boolean - 4',  'foo AND OR bar',  'foo AND bar',     'Syntax' );
test( 'Boolean - 5',  'foo AND AND bar', 'foo AND bar',     'Syntax' );
test( 'Boolean - 6',  'foo AND NOT bar', 'foo AND NOT bar', '' );
test( 'Boolean - 7',  'foo OR AND bar',  'foo OR bar',      'Syntax' );
test( 'Boolean - 8',  'foo OR OR bar',   'foo OR bar',      'Syntax' );
test( 'Boolean - 9',  'foo OR NOT bar',  'foo OR NOT bar',  '' );
test( 'Boolean - 10', 'foo NOT AND bar', 'foo NOT bar',     'Syntax' );
test( 'Boolean - 11', 'foo NOT OR bar',  'foo NOT bar',     'Syntax' );
test( 'Boolean - 12', 'foo NOT NOT bar', 'foo NOT bar',     'Syntax' );
test( 'Boolean - 13', 'AND',             '',                'preceded by' );
test( 'Boolean - 14', 'AND foo',         'foo',             'preceded by' );
test( 'Boolean - 15', 'OR',              '',                'preceded by' );
test( 'Boolean - 16', 'OR foo',          'foo',             'preceded by' );
test( 'Boolean - 17', 'NOT',             '',                'followed by' );
test( 'Boolean - 18', 'NOT foo',         'NOT foo',         '' );
test( 'Boolean - 19', 'foo AND',         'foo',             'followed by' );
test( 'Boolean - 20', 'foo OR',          'foo',             'followed by' );
test( 'Boolean - 21', 'foo NOT',         'foo',             'followed by' );
test(
    'Boolean - 22',
    'foo AND bar OR baz NOT balloo',
    'foo bar baz balloo',
    'allowed',
    allow_bool => 0
);

#===================================
# Plus Minus
#===================================
test( 'Plus Minus - 1', '+foo -bar',    '+foo -bar',    '' );
test( 'Plus Minus - 2', '+-foo -+bar',  '+foo -bar',    'Syntax' );
test( 'Plus Minus - 3', 'foo AND -bar', 'foo AND -bar', '' );
test( 'Plus Minus - 4', 'foo OR -bar',  'foo OR -bar',  '' );
test( 'Plus Minus - 5', '+ foo - bar',  'foo bar',      'must be followed' );
test(
    'Plus Minus - 6',
    'foo NOT -bar',
    'foo NOT bar',
    'cannot be followed by'
);
test(
    'Plus Minus - 7',
    'foo NOT -bar',
    'foo -bar',
    'allowed',
    allow_bool => 0,
);

#===================================
# Group
#===================================
test( 'Group - 1', 'foo(bar baz)', 'foo (bar baz)', '' );
test( 'Group - 2', 'foo(bar baz',  'foo (bar baz)', 'closing parenthesis' );
test( 'Group - 3', 'foo bar baz)', 'foo bar baz',   'Syntax' );
test(
    'Group - 4',
    '(foo AND (+bar (baz -balloo)))',
    '(foo AND (+bar (baz -balloo)))'
);

#===================================
# Boost
#===================================
test( 'Boost - 1', 'foo^2',       'foo^2',       '' );
test( 'Boost - 2', 'foo^',        'foo',         'Missing boost' );
test( 'Boost - 3', 'foo^bar',     'foo bar',     'Missing boost' );
test( 'Boost - 4', '^2 foo',      'foo',         'Syntax' );
test( 'Boost - 5', 'foo^2^3',     'foo^2',       'Syntax' );
test( 'Boost - 6', '(foo bar)^2', '(foo bar)^2', '' );
test( 'Boost - 7', 'foo^2 (bar)^3', 'foo (bar)', 'allowed',
    allow_boost => 0 );

#===================================
# Fuzzy
#===================================
test( 'Fuzzy - 1', 'foo~0.5 bar~', 'foo~0.5 bar~', '' );
test( 'Fuzzy - 2', 'foo~2',        'foo',          'between' );
test( 'Fuzzy - 3', 'foo~a',        'foo~ a' );
test( 'Fuzzy - 4', '~0.5 foo',     'foo',          'Syntax' );
test( 'Fuzzy - 5', 'foo~0.5', 'foo', 'allowed', allow_fuzzy => 0 );

#===================================
# Phrase slop
#===================================
test( 'Slop - 1', '"foo bar"~2',   '"foo bar"~2', '' );
test( 'Slop - 2', '"foo bar"~2.5', '"foo bar"~2', '' );
test( 'Slop - 3', '"foo bar"~0.5', '"foo bar"',   '' );
test( 'Slop - 4', '"foo bar"~',    '"foo bar"',   '' );
test( 'Slop - 5', '"foo bar"~a',   '"foo bar" a', '' );
test( 'Slop - 6', '"foo bar"~2', '"foo bar"', 'allowed', allow_slop => 0 );

#===================================
# Combined modifiers
#===================================
test( 'Modifiers - 1', 'foo~0.5^2', 'foo~0.5^2', '' );
test( 'Modifiers - 2', 'foo^2~0.5', 'foo^2',     'Syntax' );
test( 'Modifiers - 3', 'foo~0.5^2', 'foo~0.5', 'allowed', allow_boost => 0 );
test( 'Modifiers - 4', 'foo~0.5^2', 'foo^2', 'allowed', allow_fuzzy => 0 );

test( 'Modifiers - 5', '"foo"~2^3', '"foo"~2^3', '' );
test( 'Modifiers - 6', '"foo"^3~2', '"foo"^3',   'Syntax' );
test( 'Modifiers - 7', '"foo"~2^3', '"foo"~2', 'allowed', allow_boost => 0 );
test( 'Modifiers - 8', '"foo"~2^3', '"foo"^3', 'allowed', allow_slop => 0 );

test( 'Modifiers - 9',  '(foo)~2^3', '(foo)',   'Syntax' );
test( 'Modifiers - 10', '(foo)^2~3', '(foo)^2', 'Syntax' );

# Exists
test( 'Exists - 1', '_exists_:foo _missing_:bar', '', 'allowed' );
test(
    'Exists - 2',
    '_exists_:foo _missing_:bar',
    '_exists_:foo _missing_:bar',
    '',
    fields => 1
);
test(
    'Exists - 3',
    '_exists_:foo^2 _missing_:bar^2',
    '_exists_:foo^2',
    'allowed',
    fields => { foo => 1 }
);
test( 'Exists - 4', '_exists_: foo _missing_: bar',
    'foo bar', 'Missing', fields => 1 );

#===================================
# Ranges
#===================================
test( 'Range - 1', '[a TO b]', '', 'allowed' );
$qp = $qp->new( allow_ranges => 1 );
test( 'Range - 2',  '[a TO b]',      '[a TO b]' );
test( 'Range - 3',  '[a b]',         '[a TO b]', '' );
test( 'Range - 4',  '["a" TO "b"]',  '["a" TO "b"]', '' );
test( 'Range - 5',  '["a\"]" TO b]', '["a\\"]" TO b]', '' );
test( 'Range - 6',  '["a b]',        '["a TO b]', '' );
test( 'Range - 7',  '[a b"]',        '[a TO b"]', '' );
test( 'Range - 8',  '["a b"]',       '', 'Malformed' );
test( 'Range - 9',  '["a b"',        '"a b"', 'Reserved' );
test( 'Range - 10', 'foo:[a b]^2',   'foo:[a TO b]^2', '', fields => 1 );
test( 'Range - 11', '[ab]^2 bar', 'bar', 'Malformed' );
test( 'Range - 12', '[* TO b]',   '[* TO b]' );
test( 'Range - 13', '[a TO *]',   '[a TO *]' );
test( 'Range - 13', '[* TO *]',   '[* TO *]' );

#===================================
# Fields
#===================================
test( 'Fields - 1', 'foo:bar', 'bar', 'allowed' );
test( 'Fields - 2', 'foo:bar', 'foo:bar', '', fields => 1 );
test(
    'Fields - 3',
    'foo:bar baz:balloo',
    'bar baz:balloo',
    'allowed',
    fields => { baz => 1 }
);
test(
    'Fields - 4',
    'foo:bar~0.5^2 baz:balloo~0.5^2',
    'bar~0.5^2 baz:balloo~0.5^2',
    'allowed',
    fields => { baz => 1 }
);
test(
    'Fields - 5',
    'foo:"bar"~5^2 baz:"balloo"~5^2',
    '"bar"~5^2 baz:"balloo"~5^2',
    'allowed',
    fields => { baz => 1 }
);
test(
    'Fields - 6',
    'foo:(bar)^2 baz:(balloo)^2',
    '(bar)^2 baz:(balloo)^2',
    'allowed',
    fields => { baz => 1 }
);

#===================================
# Reserved
#===================================
test( 'Reserved - 1', 'foo " bar', 'foo bar', 'Reserved' );
test(
    'Reserved - 2',
    'foo " bar',
    'foo \\" bar',
    'Reserved',
    escape_reserved => 1
);

#===================================
# Trailing escape
#===================================
test( 'Escape - 1', 'foo\\', 'foo', 'end with' );

#all_done;

#===================================
sub test {
#===================================
    my ( $name, $in, $out, $err, @opts ) = @_;
    is( $qp->filter( $in, @opts ), $out, "Filter: $name" );
    eval { $qp->check( $in, @opts ) };
    my $throws = $@;
    $err ||= '^$';
    like $throws, qr/$err/, "Check: $name";
}

#===================================
sub tokens {
#===================================
    my ( $name, $in, @test_tokens ) = @_;
    utf8::upgrade($in);
    my $tokeniser = $qp->_init_tokeniser($in);
    my @tokens;
    while ( my $next = $tokeniser->() ) {
        push @tokens, $next->[0];
    }
    is_deeply( \@tokens, \@test_tokens, "Tokens: $name" );
}
