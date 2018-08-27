#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 16;
use Test::Differences;

use TestAppDB;

my $TABLE_DEFINITION = {
    fields => [
        {
            name => 'field',
            type => 'TYPE',
        },
        {name => 'field2', type => 'TYPE2'},
        {name => 'field3', type => 'TYPE3'},
    ],
    primary_key => [qw(id)],
    indexes     => [{fields => ['field2']}]
};

main();

sub main {
    my $app = TestAppDB->new();

    $app->pre_run();

    $app->db->make_tables({new_table1 => 'table1'});

    check_eq_table($app, 'new_table1', 'table1');

    $app->db->make_tables({new_table2 => $app->db->table2});

    check_eq_table($app, 'new_table2', 'table2');

    $app->db->make_tables(
        {
            new_table3 => $TABLE_DEFINITION
        }
    );

    check_new_table($app, 'new_table3');

    try {
        $app->db->make_tables(
            {
                new_table3 => $TABLE_DEFINITION
            }
        );
    }
    catch {
        is(shift->message, gettext('Cannot create table object, "%s" is reserved', 'new_table3'), 'Correctly message');
    }
    finally {
        ok(shift, 'Exception throw');
    };

    $app->post_run();
}

sub check_eq_table {
    my ($app, $table, $table2) = @_;

    my $meta = $app->db->get_all_meta()->{'tables'};

    eq_or_diff($meta->{$table}, $meta->{$table2}, sprintf('meta: %s vs %s', $table, $table2));

    eq_or_diff(
        [sort map {$_->name} @{$app->db->$table->fields}],
        [sort map {$_->name} @{$app->db->$table2->fields}],
        sprintf('fields: %s vs %s', $table, $table2)
    );

    eq_or_diff(
        $app->db->$table->primary_key,
        $app->db->$table2->primary_key,
        sprintf('primary key: %s vs %s', $table, $table2)
    );

    eq_or_diff($app->db->$table->indexes, $app->db->$table2->indexes, sprintf('indexes: %s vs %s', $table, $table2));

    eq_or_diff(
        $app->db->$table->foreign_keys,
        $app->db->$table2->foreign_keys,
        sprintf('foreign keys: %s vs %s', $table, $table2)
    );
}

sub check_new_table {
    my ($app, $table) = @_;

    my $meta = $app->db->get_all_meta()->{'tables'};

    eq_or_diff($meta->{$table}, $TABLE_DEFINITION, sprintf('meta new table: %s', $table));

    eq_or_diff(
        [sort map {$_->name} @{$app->db->$table->fields}],
        [sort map {$_->{'name'}} @{$TABLE_DEFINITION->{'fields'}}],
        sprintf('fields new table: %s', $table)
    );

    eq_or_diff(
        $app->db->$table->primary_key,
        $TABLE_DEFINITION->{'primary_key'},
        sprintf('primary key new table: %s', $table)
    );

    eq_or_diff($app->db->$table->indexes, $TABLE_DEFINITION->{'indexes'}, sprintf('indexes new table: %s', $table));
}
