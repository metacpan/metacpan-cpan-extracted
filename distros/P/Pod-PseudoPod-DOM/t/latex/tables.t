use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file           = read_file( catfile( qw( t test_file.pod ) ) );
my ($doc, $result) = parse( $file, filename => 'tables_test.tex' );

like $result,
    qr!\\begin\{center}\n\\LTXtable\{\\linewidth}\{tables_test_table0.tex}!,
    'table should translate to LTXtable with external ref';

my $tables = $doc->tables;
is keys %$tables, 1,
    'tables() method on doc object should return tables hashref';
ok exists $tables->{'tables_test_table0.tex'},
    '... keyed on table name reference from doc';

$result = $tables->{'tables_test_table0.tex'};
like $result, qr!\\begin\{longtable}\{\| X \| X \|}\n\\hline!,
    '... containing appropriate table header';
like $result,
    qr!\\emph\{Left Column} & \\emph\{Right Column}\\\\\\endhead\\hline!,
    '... and head row';
like $result, qr!Left Cell One & \\begin\{itemize}\n!,
    '... and body cell';
like $result, qr!\\item First.+\\item Second.+\\item Third.+\\end\{itemize}!s,
    '... with list in cell';
like $result, qr!\\end\{itemize}\\\\\\hline!s,
    '... and list ending';
like $result, qr!Left Cell Two & Right Cell Two\\\\\\hline\n\\caption\{!,
    '... ending with caption';
like_string $result,
    qr!\\caption\{A Table of \\emph\{Fun} Things}\n\\end\{longtable}!,
    '... and table ending';

done_testing;
