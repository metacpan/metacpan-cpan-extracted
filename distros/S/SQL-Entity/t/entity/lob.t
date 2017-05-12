use strict;
use warnings;

use Test::More tests => 5;
use SQL::Entity::Table;

BEGIN{
    use_ok('SQL::Entity::Column::LOB', ':all');
}

{
    my $column = SQL::Entity::Column::LOB->new(name => 'image', size_column => 'image_size');
    isa_ok($column, 'SQL::Entity::Column::LOB');
    is($column->as_string, 'image', 'should strigify lob column');
}

{
    my $column = sql_lob(name => 'image', size_column => 'image_size');
    isa_ok($column, 'SQL::Entity::Column::LOB');
}

my $table = SQL::Entity::Table->new(name => 'emp');
my $lob = sql_lob(name => 'image', size_column => 'image_size');
$table->add_lobs($lob);
is($table->lob('image'), $lob, 'should have lob');
