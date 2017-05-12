use strict;
use warnings;

use Test::More tests => 6;

BEGIN{
    use_ok('SQL::Entity::Column', ':all');
}

{
    my $column = SQL::Entity::Column->new(name => 'empno');
    isa_ok($column, 'SQL::Entity::Column');
    is($column->as_string, 'empno', 'should strigify column');
}

{
    my $column = sql_column(name => 'empno');
    isa_ok($column, 'SQL::Entity::Column');
}

{
    my $column = sql_column(
        id         => 'col1_col2',
        expression => 'col1||col2',
        updatable  => 0,
        insertable => 0,
    );
    is($column->updatable, 0, "should not be updatable");
    is($column->as_string, "(col1||col2) AS col1_col2", "should stingyfy column");
}

