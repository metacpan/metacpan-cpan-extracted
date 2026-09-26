use Test2::V0 -no_srand => 1;
use SQL::AST::Simple qw( parse unparse parse_expr unparse_expr );

subtest 'round trip' => sub {
    my $sql = 'SELECT a, b, 123, myfunc(b) FROM table_1 WHERE a > b AND b < 100 ORDER BY a DESC, b';
    my $ast = parse($sql);
    is $ast, array {
        item hash {
            field Query => hash { etc };
            end;
        };
        end;
    }, 'one Query statement';
    is unparse($ast), $sql, 'unparse reproduces input';
};

subtest 'modify' => sub {
    my $ast = parse('SELECT a FROM t');
    my $table = $ast->[0]{Query}{body}{Select}{from}[0]{relation}{Table}{name}[0]{Identifier};
    is $table->{value}, 't', 'found table name';
    $table->{value} = 'u';
    $table->{quote_style} = '"';
    is unparse($ast), 'SELECT a FROM "u"', 'modified table name and quoting';
};

subtest 'multiple statements' => sub {
    my $ast = parse('SELECT 1; SELECT 2');
    is scalar(@$ast), 2, 'two statements';
    is unparse($ast), 'SELECT 1; SELECT 2', 'joined with semicolon';
    is unparse($ast->[1]), 'SELECT 2', 'single statement hashref';
    is unparse([]), '', 'empty list';
};

subtest 'pretty' => sub {
    my $ast = parse('SELECT a, b FROM t');
    my $sql = unparse($ast, pretty => 1);
    like $sql, qr/\n/, 'pretty output has newlines';
    is unparse(parse($sql)), 'SELECT a, b FROM t', 'pretty output parses back';
};

subtest 'dialect' => sub {
    my $ast = parse('SELECT a::int FROM t', dialect => 'PostgreSQL');
    is unparse($ast), 'SELECT a::INT FROM t', 'postgresql cast';
    like dies { parse('SELECT 1', dialect => 'bogus') }, qr/unknown dialect: bogus/, 'unknown dialect';
};

subtest 'unicode' => sub {
    my $sql = "SELECT 'h\x{e9}llo', '\x{1F60A}' FROM \"t\x{e4}ble\"";
    my $ast = parse($sql);
    is $ast->[0]{Query}{body}{Select}{from}[0]{relation}{Table}{name}[0]{Identifier}{value},
        "t\x{e4}ble", 'identifier decoded as characters';
    is unparse($ast), $sql, 'round trip preserves wide characters';
};

subtest 'expressions' => sub {
    my $expr = parse_expr("a > 1 AND b = 'x'");
    is $expr, hash { field BinaryOp => hash { etc }; end }, 'BinaryOp node';
    is unparse_expr($expr), "a > 1 AND b = 'x'", 'round trip';

    my $ast = parse('SELECT a FROM t');
    $ast->[0]{Query}{body}{Select}{selection} = $expr;
    is unparse($ast), "SELECT a FROM t WHERE a > 1 AND b = 'x'", 'spliced into a statement';
    is unparse_expr(parse('SELECT 1 WHERE c < 2')->[0]{Query}{body}{Select}{selection}), 'c < 2', 'lifted out of a statement';

    is unparse_expr(parse_expr('a::int', dialect => 'postgresql')), 'a::INT', 'dialect option';
    is unparse_expr(parse_expr("'h\x{e9}llo'")), "'h\x{e9}llo'", 'unicode';

    like dies { parse_expr('a > 1 foo') }, qr/Expected: EOF, found: foo at Line: 1, Column: 7/, 'trailing tokens';
    like dies { parse_expr('') }, qr/Expected: an expression/, 'empty';
    like dies { parse_expr(undef) }, qr/sql must be defined/, 'undef sql';
    like dies { parse_expr('a', foo => 1) }, qr/unknown options: foo/, 'bad parse_expr option';
    like dies { unparse_expr({ Bogus => 1 }) }, qr/unknown variant/, 'invalid expr';
    like dies { unparse_expr([]) }, qr/must be a hash reference/, 'not a hash reference';
    like dies { unparse_expr({}, pretty => 1) }, qr/unknown options: pretty/, 'bad unparse_expr option';
};

subtest 'errors' => sub {
    like dies { parse('SELEC 1') }, qr/Expected: an SQL statement, found: SELEC at Line: 1, Column: 1/, 'parse error message';
    like dies { parse(undef) }, qr/sql must be defined/, 'undef sql';
    like dies { parse('SELECT 1', foo => 1) }, qr/unknown options: foo/, 'bad parse option';
    like dies { unparse([{ Bogus => 1 }]) }, qr/unknown variant/, 'invalid ast';
    like dies { unparse('SELECT 1') }, qr/must be an array or hash reference/, 'not a reference';
    like dies { unparse([], foo => 1) }, qr/unknown options: foo/, 'bad unparse option';
};

done_testing;
