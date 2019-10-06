#!perl

# This script includes a Perl implementation of some of the tests from
# ast_tester/testtable.f.

use strict;

use Test::More tests => 22;
use Test::Number::Delta;

require_ok('Starlink::AST');

do {
    my $table = new Starlink::AST::Table('');
    isa_ok($table, 'Starlink::AST::Table');

    $table->AddColumn('Fred', Starlink::AST::KeyMap::AST__FLOATTYPE(), [5, 2], '');
    is($table->GetI('NColumn'), 1);
    is($table->ColumnName(1), 'FRED');
    is($table->GetI('ColumnType(Fred)'), Starlink::AST::KeyMap::AST__FLOATTYPE());
    is_deeply($table->ColumnShape('Fred'), [5, 2]);

    $table->RemoveColumn('Fred');
    is($table->GetI('NColumn'), 0);

    $table->AddColumn('Fred', Starlink::AST::KeyMap::AST__FLOATTYPE(), [], 'pW');
    $table->MapPut0D('Fred(1)', -123.0, 'com 1');
    $table->MapPut0D('Fred(2)', 123.0, 'com 1');

    delta_ok($table->MapGet0D('Fred(2)'), 123.0);
    is($table->GetC('ColumnUnit(Fred)'), 'pW');

    is($table->GetI('NRow'), 2);
    $table->RemoveRow(2);
    is($table->GetI('NRow'), 1);

    $table->AddParameter('COLOUR');
    ok($table->HasParameter('COLOUR'));
    is($table->ParameterName(1), 'COLOUR');

    $table->MapPut0C('COLOUR', 'Red', '');
    is($table->MapGet0C('COLOUR'), 'Red');

    $table->RemoveParameter('COLOUR');
    ok(! $table->HasParameter('COLOUR'));

    $table->MapPut0D('Fred(6)', 321.0, '');
    is($table->GetI('NRow'), 6);
    $table->MapRemove('Fred(6)');
    $table->PurgeRows();
    is($table->GetI('NRow'), 1);

    my $fchan = new Starlink::AST::FitsChan();
    my $ftable = new Starlink::AST::FitsTable($fchan, '');
    isa_ok($ftable, 'Starlink::AST::FitsTable');

    $fchan = new Starlink::AST::FitsChan();
    $ftable->PutTableHeader($fchan);

    $ftable->AddColumn("testcol", Starlink::AST::KeyMap::AST__INTTYPE(), [], "");
    my ($null, $wasset, $hasnull) = $ftable->ColumnNull('testcol');
    ok(! $wasset);

    $ftable->ColumnNull('testcol', 999);
    ($null, $wasset, $hasnull) = $ftable->ColumnNull('testcol');
    is($null, 999);
    ok($wasset);

    $ftable->MapPut0I('testcol(1)', 111, '');
    is($ftable->ColumnSize('testcol'), 4);
};
