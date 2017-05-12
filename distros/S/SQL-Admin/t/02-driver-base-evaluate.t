
use strict;
use warnings;

use FindBin;
use lib map $FindBin::Bin . '/' . $_, qw( . ../lib ../lib/perl5 );

use Data::Dumper;
use Test::More;
END { done_testing }

######################################################################

my $CLASS = 'SQL::Admin::Driver::Base::Evaluate';
my $CAT = 'SQL::Admin::Catalog';

my $CAT_SEQ = $CAT . '::Sequence';
my $CAT_IDX = $CAT . '::Index';
my $CAT_TBL = $CAT . '::Table';

######################################################################

use_ok ($CLASS);
use_ok ($CAT);

my $evl = new_ok ($CLASS);
my $cat = new_ok ($CAT);

######################################################################
######################################################################
sub create_sequence {                    # ;
    $evl->evaluate ($cat, {
        create_sequence => {
            sequence_name => { schema => 'bbb', name => 'aaa' },
            sequence_type => 'int4',
            sequence_options => {
                sequence_start_with   => 1_000,
                sequence_increment_by => 133,
                sequence_minvalue     => 1_000,
                sequence_maxvalue     => 10_000,
                sequence_cache        => 50,
            },
        }});

    {
        ok (exists $cat->{sequence}{'bbb.aaa'}, 'sequence: exists');
        my $seq = $cat->{sequence}{'bbb.aaa'};

        isa_ok ($seq, $CAT_SEQ, 'sequence:');
        is ($seq->name,         'aaa',  'sequence: name');
        is ($seq->schema,       'bbb',  'sequence: schema');
        is ($seq->start_with,   1_000,  'sequence: start_with');
        is ($seq->increment_by, 133,    'sequence: increment_by');
        is ($seq->minvalue,     1_000,  'sequence: minvalue');
        is ($seq->maxvalue,     10_000, 'sequence: maxvalue');
        is ($seq->cache,        50,     'sequence: cache');
    }

}


######################################################################
######################################################################
sub create_index {                       # ;
    $evl->evaluate ($cat, {
        create_index => {
            index_name        => { schema => 'bbb', name => 'aa1' },
            table_name        => { schema => 'bbb', name => 'ccc' },
            index_column_list => [
                { column_name => 'ddd' },
            ]
        }});

    {
        ok (exists $cat->{index}{'bbb.aa1'}, 'index 1: exists');
        my $obj = $cat->{index}{'bbb.aa1'};

        isa_ok ($obj, $CAT_IDX, 'index 1:');
        is ($obj->name, 'aa1', 'index 1: name');
        is ($obj->schema, 'bbb', 'index 1: schema');
        ok (! $obj->unique,      'index 1: unique');
        is_deeply ($obj->column_list, [ ['ddd'] ], 'index 1: column list');

        my $table = $obj->table;
        isa_ok ($table, $CAT_TBL, 'index 1: table');
        is ($table->fullname, 'bbb.ccc', 'index 1: table fullname');
    }

    $evl->evaluate ($cat, {
        create_index => {
            index_unique      => 1,
            index_name        => { schema => 'bbb', name => 'aa2' },
            table_name        => { schema => 'bbb', name => 'ccc' },
            index_column_list => [
                { column_name => 'ddd' },
                { column_name => 'eee', column_order => 'desc' },
            ],
            index_options     => { aaa   => 10 },
            index_hints       => { db2_pctfree   => 10 },
        }});

    {
        ok (exists $cat->{index}{'bbb.aa2'}, 'index 2: exists');
        my $obj = $cat->{index}{'bbb.aa2'};

        isa_ok ($obj, $CAT_IDX, 'index 2:');
        is ($obj->name, 'aa2', 'index 2: name');
        is ($obj->schema, 'bbb', 'index 2: schema');
        ok ($obj->unique,      'index 2: unique');
        is_deeply (
            $obj->column_list, [
                ['ddd'],
                ['eee', 'DESC'],
            ], 'index 2: column list');

        my $table = $obj->table;
        isa_ok ($table, $CAT_TBL, 'index 2: table');
        is ($table->fullname, 'bbb.ccc', 'index 2: table fullname');

        is ($obj->hint ('aaa'), 10, 'index 2: hint aaa');
        is ($obj->hint ('db2_pctfree'), 10, 'index 2: hint db2_pctfree');
    }

}


######################################################################
######################################################################
sub create_table {                       # ;
    my $cat = $CAT->new;

    $evl->evaluate ($cat, {
        create_table => {
            table_name => { name => 'aaa', schema => 'bbb' },
            table_hints => { 'haa' => 'hav', 'hbb' => 'hbv' },
            table_content => [ {
                column_definition => {
                    data_type   => 'int4',
                    column_not_null    => 1,
                    column_name => 'caa'
                }
            }, {
                column_definition => {
                    data_type => 'int2',
                    column_not_null => 1,
                    column_name => 'cbb',
                    default_clause => { 'integer' => 1 },
                }
            }, {
                column_definition => {
                    data_type => 'varchar',
                    column_name => 'ccc',
                    size => 160
                }
            } ],
        }
    });

    {
        ok (exists $cat->{table}{'bbb.aaa'}, 'create table CT-1: table exists');
        my $obj = $cat->{table}{'bbb.aaa'};

        is ($obj->hint ('haa'), 'hav', 'create table CT-1: hint haa');
        is ($obj->hint ('hbb'), 'hbv', 'create table CT-1: hint hbb');

        my $map = $obj->column;

        ok (exists $map->{caa}, 'create table CT-1: column caa');
        ok (exists $map->{cbb}, 'create table CT-1: column cbb');
        ok (exists $map->{ccc}, 'create table CT-1: column ccc');

        is_deeply ($map->{caa}->type, { type => 'int4' }, 'create table CT-1: caa->type');
        is_deeply ($map->{cbb}->type, { type => 'int2' }, 'create table CT-1: cbb->type');
        is_deeply ($map->{ccc}->type, { type => 'varchar', size => 160 }, 'create table CT-1: ccc->type');

        is ($map->{caa}->fullname, 'bbb.aaa.caa', 'create table CT-1: caa->fullname');
        is ($map->{cbb}->fullname, 'bbb.aaa.cbb', 'create table CT-1: cbb->fullname');
        is ($map->{ccc}->fullname, 'bbb.aaa.ccc', 'create table CT-1: ccc->fullname');

        ok ($map->{caa}->not_null, 'create table CT-1: caa->not_null');
        ok ($map->{cbb}->not_null, 'create table CT-1: cbb->not_null');
        ok (! $map->{ccc}->not_null, 'create table CT-1: ccc->not_null');

        ok (! $map->{caa}->default, 'create table CT-1: caa->defaut');
        is_deeply ($map->{cbb}->default, { integer => 1 }, 'create table CT-1: cbb->default');
        ok (! $map->{ccc}->default, 'create table CT-1: ccc->defaut');
    }

}


######################################################################
######################################################################
sub alter_table_set_hints {              # ;
    my $cat = $CAT->new;

    $evl->evaluate ($cat, {
        alter_table => {
            table_name => { name => 'aaa', 'schema' => 'bbb' },
            alter_table_actions => [
                { set_table_hint => { db2_locksize => 'ROW' } },
                { set_table_hint => { db2_append   => 1 } },
            ],
        }});

    {
        ok (exists $cat->{table}{'bbb.aaa'}, 'alter table: exists');
        my $obj = $cat->{table}{'bbb.aaa'};

        isa_ok ($obj, $CAT_TBL, 'alter table:');
        is ($obj->hint ('db2_locksize'), 'ROW', 'alter table: set_table_hint (db2_locksize)');
        is ($obj->hint ('db2_append'), 1, 'alter table: set_table_hint (db2_append)');
    }

}


######################################################################
######################################################################
sub alter_table_primary_key {            # ;
    my $cat = $CAT->new;

    $evl->evaluate ($cat, {
        alter_table => {
            table_name => { name => 'aaa', 'schema' => 'bbb' },
            alter_table_actions => [ {
                add_constraint => { primary_key_constraint => {
                        constraint_name => 'SQL050906153239510',
                        column_list => [ 'zzz' ],
                    }}
            } ],
        }});

    {
        ok (exists $cat->{table}{'bbb.aaa'}, 'alter table 1: exists');
        my $obj = $cat->{table}{'bbb.aaa'};

        ok ($obj->primary_key, 'alter table 1: primary key defined');
        is ($obj->primary_key->fullname, 'bbb.aaa.primary_key.zzz', 'alter table 1: primary key name');
        #print Data::Dumper::Dumper ($cat);
    }

    ##################################################################

    $cat = $CAT->new;
    $evl->evaluate ($cat, {
        alter_table => {
            table_name => { name => 'aaa', schema => 'bbb' },
            alter_table_actions => [ {
                add_constraint => { primary_key_constraint => {
                    constraint_name => 'SQL061025115309580',
                    column_list     => [ 'zzz', 'yyy' ]
                } }
            } ],
        }

    });

    {
        ok (exists $cat->{table}{'bbb.aaa'}, 'alter table 2: exists');
        my $obj = $cat->{table}{'bbb.aaa'};

        ok ($obj->primary_key, 'alter table 2: primary key defined');
        is ($obj->primary_key->fullname, 'bbb.aaa.primary_key.zzz.yyy', 'alter table 2: primary key name');
    }
}


######################################################################
######################################################################
sub alter_table_unique {                 # ;
    my $cat = $CAT->new;

    $evl->evaluate ($cat, {
        alter_table => {
            table_name => { name => 'aaa', 'schema' => 'bbb' },
            alter_table_actions => [ {
                add_constraint => { unique_constraint => {
                    constraint_name => 'SQL051227180539060',
                    column_list    => [ 'zzz', 'xxx' ]
                } }
            } ],
        }});

    {
        ok (exists $cat->{table}{'bbb.aaa'}, 'alter table UQ-1: exists');
        my $obj = $cat->{table}{'bbb.aaa'};

        ok ($obj->unique, 'alter table UQ-1: unique defined');
        my $map = $obj->unique;
        is (ref $map, 'HASH', 'alter table UQ-1: unique is HASH');
        my ($c) = values %$map;

        is ($c->fullname, 'bbb.aaa.unique.zzz.xxx', 'alter table UQ-1: fullname');
        is_deeply ($c->column_list, ['zzz', 'xxx'], 'alter table UQ-1: column list');
    }

    ##################################################################
}


######################################################################
######################################################################
sub alter_table_foreign_key {            # ;
    my $cat = $CAT->new;

    $evl->evaluate ($cat, {
        alter_table => {
            table_name => { name => 'aaa', 'schema' => 'bbb' },
            alter_table_actions => [ {
                add_constraint => { foreign_key_constraint => {
                    constraint_name  => 'SQL050926155612920',
                    update_rule      => 'no_action',
                    delete_rule      => 'cascade',
                    referenced_table => { schema => 'bbb', name => 'rrr' },
                    referenced_column_list  => [ 'zzz' ],
                    referencing_column_list => [ 'xxx' ]
                } }
            } ],
        }
    });

    {
        ok (exists $cat->{table}{'bbb.aaa'}, 'alter table FK-1: table exists');
        my $obj = $cat->{table}{'bbb.aaa'};

        ok ($obj->foreign_key, 'alter table FK-1: foreign_key defined');
        my $map = $obj->foreign_key;
        is (ref $map, 'HASH', 'alter table FK-1: foreign_key is HASH');
        my ($c) = values %$map;

        is ($c->fullname, 'bbb.aaa.foreign_key.xxx{bbb.rrr.zzz}', 'alter table FK-1: fullname');
        is_deeply ($c->referenced_column_list, ['zzz'], 'alter table FK-1: referenced column list');
        is_deeply ($c->referencing_column_list, ['xxx'], 'alter table FK-1: referencing column list');
        is ($c->update_rule => 'no_action', 'alter table FK-1: update rule');
        is ($c->delete_rule => 'cascade', 'alter table FK-1: delete rule');
    }
}


######################################################################
######################################################################
sub alter_table_add_column {             # ;
    my $cat = $CAT->new;

    $evl->evaluate ($cat, {
        create_table => {
            table_name  => { name => 'aaa', schema => 'bbb' },
            table_content => [ {
                column_definition => {
                    column_name => 'caa',
                    data_type   => 'int4',
                    column_not_null    => 1,
                }
            } ],
        }
    }, {
        alter_table => {
            table_name  => { name => 'aaa', schema => 'bbb' },
            alter_table_actions => [ {
                add_column => [ {
                    column_definition => {
                        data_type => 'int4',
                        column_not_null => 1,
                        column_name => 'operator_id',
                        default_clause => { integer => 0 }
                    }
                } ]
            } ]
        },
    });
}


######################################################################
######################################################################
sub main {                               # ;
    create_sequence;
    create_index;
    create_table;
    alter_table_set_hints;
    alter_table_primary_key;
    alter_table_unique;
    alter_table_foreign_key;
    alter_table_add_column;

    # print Data::Dumper::Dumper ($cat);
}


######################################################################
######################################################################

main;
