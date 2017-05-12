#!perl -T

use Test::More tests => 15;
use Table::Simple;
use Table::Simple::Column;

new_ok("Table::Simple");

my $table = new Table::Simple;
can_ok($table, "meta");
can_ok($table, "_inc_row_count");
can_ok($table, "row_count");
can_ok($table, "add_column");
can_ok($table, "extract_columns");
can_ok($table, "_extract_columns_moose");
can_ok($table, "_extract_columns_hashref");
can_ok($table, "_get_value_using_introspection");
can_ok($table, "extract_row");


new_ok("Table::Simple::Column" => [ name=> 'Foo' ] );
my $column = Table::Simple::Column->new( name => 'Foo' );
can_ok($column, "meta");
can_ok($column, "width");
can_ok($column, "name");
$column->width( length $column->name );
ok($column->width ==  3, "width matches name length");

