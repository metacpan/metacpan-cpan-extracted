
package SQL::Admin::Driver::DB2::DBI;
use base qw( SQL::Admin::Driver::Base::DBI );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

use SQL::Admin::Driver::DB2::Parser;

######################################################################

our %TYPE_MAP = (
    smallint   => 'int2',
    integer    => 'int4',
    bigint     => 'int8',
    vargraphic => 'varchar',
    varchar    => 'varchar',
    character  => 'character',
    decimal    => 'decimal',
    real       => 'real',
    date       => 'date',
    time       => 'time',
    timestamp  => 'timestamp',
);

our %TYPE_WITH_SIZE = (
    varchar    => 1,
    character  => 1,
    vargraphic => 2,
    decimal    => 1,
);

our %TYPE_WITH_SCALE = (
    decimal    => 1,
);


######################################################################
######################################################################
sub lcws ( $ ) {                         # ;
    $_[0] =~ s/\s+$//;
    $_[0] = lc $_[0];
}


######################################################################
######################################################################
sub driver {                             # ;
    shift;
}


######################################################################
######################################################################
sub parser {                             # ;
    my $self = shift;
    $self->{parser} ||= SQL::Admin::Driver::DB2::Parser->new;
}


######################################################################
######################################################################
sub _list_sequence {                     # ;
    my ($self, $catalog) = @_;

    my ($sql, @bind) = $self->sqla->select (
        [ 'syscat.sequences' ],
        [ '*' ],
        {
            ORIGIN  => 'U',
            SEQTYPE => 'S',
            seqschema => { 'not like' => 'SYS%' },
        },
    );

    my $sth = $self->sth ($sql, @bind);
    while (my $row = $sth->fetchrow_hashref) {
        my $obj = $catalog->add (sequence => (
            name   => lc $row->{SEQNAME},
            schema => lc $row->{SEQSCHEMA},
        ));
        $obj->increment_by ($row->{INCREMENT});
        $obj->start_with   ($row->{START});
        $obj->minvalue     ($row->{MINVALUE});
        $obj->maxvalue     ($row->{MAXVALUE});
        $obj->cache        ($row->{CACHE});
    }

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub _query_table {                       # ;
    my ($self, @schemas) = @_;
    $_ = uc for @schemas;

    $self->sqla->select (
        [ 'syscat.tables' ],
        [
            'tabschema as table_schema',
            'tabname   as table_name',
            'tbspace   as hint_db2_tablespace',
            'case when append_mode = \'N\' then null
                  when append_mode = \'Y\' then \'ON\'
                  else null
             end as hint_db2_append',
            'case when pctfree > -1 then pctfree else null end as hint_db2_pctfree',
            'case when locksize = \'I\' then \'BLOCK\'
                  when locksize = \'R\' then null
                  when locksize = \'T\' then \'TABLE\'
                  else null
             end as hint_db2_locksize',
            'colcount as info_db_colcount',
            'case when card > -1 then card
                  else null
             end as info_db_rows',
        ],
        {
            tabschema => ( @schemas ? \ @schemas : { 'not like' => 'SYS%' }),
            type      => 'T',
        },
    );
}


######################################################################
######################################################################
sub _query_table_column {                # ;
    my ($self, @schemas) = @_;
    $_ = uc for @schemas;
    $self->sqla->select (
        [ 'syscat.columns c', 'syscat.tables t' ],
        [
            'c.tabschema as table_schema',
            'c.tabname   as table_name',
            'c.colname   as column_name',
            'c.typename  as data_type',
            'c.length    as data_type_size',
            'c.scale     as data_type_scale',
            'case when c.nulls = \'N\' then 1
                  else null
             end as not_null',
            'c.default',
            'c.keyseq    as primary_key_index',

            'c.colno', 't.colcount',
        ],
        {
            'c.tabschema' => ( @schemas ? \ @schemas : { not_like => 'SYS%' }),
            't.tabschema' => \ ' = c.tabschema',
            't.tabname'   => \ ' = c.tabname',
            't.type'      => 'T',
        },
        [ 't.tabschema, t.tabname, c.colno' ],
    );

}


######################################################################
######################################################################
sub _query_table_column_autoincrement {  # ;
    my ($self, @schemas) = @_;
    $_ = uc for @schemas;
    $self->sqla->select (
        [ 'syscat.colidentattributes' ],
        [
            'tabschema as table_schema',
            'tabname   as table_name',
            'colname   as column_name',
            'start     as start_with',
            'increment as increment_by',
            'minvalue',
            'maxvalue',
            'cache',
        ],
        {
            'tabschema' => ( @schemas ? \ @schemas : { not_like => 'SYS%' }),
        },
    );
}


######################################################################
######################################################################
sub _query_constraint_primary_key {      # ;
    my ($self, @schemas) = @_;
    $_ = uc for @schemas;
    $self->sqla->select (
        [ 'syscat.columns c', 'syscat.tables t' ],
        [
            'c.tabschema  as table_schema',
            'c.tabname    as table_name',
            'c.colname    as column_name',
            'c.keyseq     as colno',
            't.keycolumns as colcount',
        ],
        {
            'c.tabschema' => ( @schemas ? \ @schemas : { not_like => 'SYS%' }),
            't.tabschema' => \ ' = c.tabschema',
            't.tabname'   => \ ' = c.tabname',
            't.type'      => 'T',
            'c.keyseq'    => { '!=', undef },
        },
        [ 'c.tabschema, c.tabname, c.keyseq' ],
    );

}


######################################################################
######################################################################
sub _query_constraint_unique {           # ;
    my ($self, @schemas) = @_;
    $_ = uc for @schemas;
    $self->sqla->select (
        [ 'syscat.constdep c', 'syscat.indexes i', 'syscat.indexcoluse u' ],
        [
            'c.tabschema as table_schema',
            'c.tabname   as table_name',
            'c.constname as constraint_name',
            'u.colname   as column_name',
            'u.colseq    as colno',
            'i.colcount',
        ],
        {
            'c.tabschema' => ( @schemas ? \ @schemas : { not_like => 'SYS%' }),
            'c.bschema'   => \ ' = i.indschema',
            'c.bname'     => \ ' = i.indname',
            'u.indschema' => \ ' = i.indschema',
            'u.indname'   => \ ' = i.indname',
            'i.user_defined' => 0,
            'i.uniquerule'   => 'U',
        },
        [ 'c.tabschema, c.tabname, c.constname, u.colseq' ],
    );

}


######################################################################
######################################################################
sub _query_constraint_foreign_key {      # ;
    my ($self, @schemas) = @_;
    $_ = uc for @schemas;
    $self->sqla->select (
        [ 'syscat.references fk', 'syscat.keycoluse tc', 'syscat.keycoluse rc' ],
        [
            'fk.constname    as constraint_name',
            'fk.tabschema    as table_schema',
            'fk.tabname      as table_name',
            'tc.colname      as column_name',
            'fk.reftabschema as reftable_schema',
            'fk.reftabname   as reftable_name',
            'rc.colname      as refcolumn_name',
            'case when fk.deleterule = \'A\' then \'no_action\'
                  when fk.deleterule = \'C\' then \'cascade\'
                  when fk.deleterule = \'N\' then \'set_null\'
                  when fk.deleterule = \'R\' then \'restrict\'
             end as delete_rule',
            'case when fk.updaterule = \'A\' then \'no_action\'
                  when fk.updaterule = \'C\' then \'cascade\'
                  when fk.updaterule = \'N\' then \'set_null\'
                  when fk.updaterule = \'R\' then \'restrict\'
             end as update_rule',

            'tc.colseq       as colno',
            'fk.colcount',
        ],
        {
            'fk.tabschema'  => ( @schemas ? \ @schemas : { not_like => 'SYS%' }),
            'fk.constname'  => \ ' = tc.constname',
            'fk.refkeyname' => \ ' = rc.constname',
            'tc.colseq'     => \ ' = rc.colseq',
        },
        [ 'fk.tabschema, fk.tabname, fk.constname, tc.colseq' ],
    );
}


######################################################################
######################################################################
sub _query_index {                       # ;
    my ($self, @schemas) = @_;
    $_ = uc for @schemas;
    $self->sqla->select (
        [ 'syscat.indexes ix', 'syscat.indexcoluse cu' ],
        [
            'ix.tabschema    as table_schema',
            'ix.tabname      as table_name',
            'ix.indschema    as index_schema',
            'ix.indname      as index_name',
            'cu.colname      as column_name',
            'case when cu.colorder = \'A\' then \'ASC\'
                  when cu.colorder = \'D\' then \'DESC\'
                  when cu.colorder = \'I\' then null
             end as column_order',
            'case when ix.uniquerule = \'U\' then 1
                  when ix.uniquerule = \'D\' then 0
                  else null
             end as unique',
            'case when ix.pctfree > -1 then ix.pctfree
                  else null
             end as hint_db2_pctfree',

            'cu.colseq       as colno',
            'ix.colcount     as colcount',
        ],
        {
            'ix.indschema'  => ( @schemas ? \ @schemas : { not_like => 'SYS%' }),
            'cu.indschema'  => \ ' = ix.indschema',
            'cu.indname'    => \ ' = ix.indname',
            'ix.uniquerule' => [ 'U', 'D' ],
            'ix.user_defined' => 1,
        },
        [ 'ix.indschema, ix.indname, cu.colseq' ],
    );
}


######################################################################
######################################################################
sub load_table {                         # ;
    my ($self, $catalog, @schemas) = @_;

    my $sth = $self->execute ($self->_query_table (@schemas));
    while (my $row = $sth->fetchrow_hashref) {
        lcws $_ for @$row{qw{ table_schema table_name }};

        my $table = $catalog->add (table => (
            schema => $row->{table_schema},
            name   => $row->{table_name},
        ));

        while (my ($key, $value) = each %$row) {
            next unless defined $value;

            $table->hint ($1, $value) if $key =~ m/^hint_(.*)/;
            $table->info ($1, $value) if $key =~ m/^info_(.*)/;
        }
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_index {                         # ;
    my ($self, $catalog, @schemas) = @_;

    my $column_list = [];
    my $sth = $self->execute ($self->_query_index (@schemas));
    while (my $row = $sth->fetchrow_hashref) {
        push @$column_list, [ lcws $row->{column_name}, $row->{column_order} ];

        if ($row->{colno} == $row->{colcount}) {
            my $index = $catalog->add (index => (
                schema => lcws $row->{index_schema},
                name   => lcws $row->{index_name}
            ));

            $index->table ($catalog->add (table => (
                schema => lcws $row->{table_schema},
                name   => lcws $row->{table_name}
            )));

            $index->unique (1) if $row->{unique};
            $index->column_list ($column_list);

            while (my ($key, $value) = each %$row) {
                next unless defined $value;
                $index->hint ($1, $value) if $key =~ m/^hint_(.*)/;
            }

            $column_list = [];
        }
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_table_column {                  # ;
    my ($self, $catalog, @schemas) = @_;

    my $sth = $self->execute ($self->_query_table_column (@schemas));
    while (my $row = $sth->fetchrow_hashref) {
        my $column = $catalog->add (table => (
            schema => lcws $row->{table_schema},
            name   => lcws $row->{table_name},
        ))->add (column => (
            name => lcws $row->{column_name}
        ));

        my $type = lcws $row->{data_type};
        die "Unknown data type: $type\n" unless exists  $TYPE_MAP{ $type };
        $column->type ({
            type => $TYPE_MAP{ $type },
            (map +(size  => $_ * $row->{data_type_size}),  grep $_, $TYPE_WITH_SIZE{ $type }),
            (map +(scale =>      $row->{data_type_scale}), grep $_, $TYPE_WITH_SCALE{ $type }),
        });

        ##############################################################

        $column->not_null (1)
          if $row->{not_null};

        $column->default ($self->parser->default_clause_value ($_))
          for grep defined, $row->{default};
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_table_column_autoincrement {    # ;
    my ($self, $catalog, @schemas) = @_;

    my $sth = $self->execute ($self->_query_table_column_autoincrement (@schemas));

    while (my $row = $sth->fetchrow_hashref) {
        my $table = $catalog->get (table => (
            name   => lcws $row->{table_name},
            schema => lcws $row->{table_schema},
        ))
          or next;

        my $column = $table->column (lcws $row->{column_name})
          or next;

        $column->autoincrement (1);
        map $column->autoincrement_hint ($_ => $row->{$_}),
          grep defined $row->{$_},
            qw( start_with increment_by minvalue maxvalue cache );
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_constraint_primary_key {        # ;
    my ($self, $catalog, @schemas) = @_;

    my $column_list = [];
    my $sth = $self->execute ($self->_query_constraint_primary_key (@schemas));

    while (my $row = $sth->fetchrow_hashref) {
        push @$column_list, lcws $row->{column_name};

        if ($row->{colno} == $row->{colcount}) {
            my $constr = $catalog->add (table => (
                schema => lcws $row->{table_schema},
                name   => lcws $row->{table_name},
            ))->add (primary_key => (
                column_list => $column_list
            ));

            $column_list = [];
        }
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_constraint_unique {             # ;
    my ($self, $catalog, @schemas) = @_;

    my $column_list = [];
    my $sth = $self->execute ($self->_query_constraint_unique (@schemas));

    while (my $row = $sth->fetchrow_hashref) {
        push @$column_list, lcws $row->{column_name};

        if ($row->{colno} == $row->{colcount}) {
            my $constr = $catalog->get (table => (
                schema => lcws $row->{table_schema},
                name   => lcws $row->{table_name}
            ))->add (unique => (
                column_list => $column_list,
                name        => lcws $row->{constraint_name},
            ));

            $column_list = [];
        }
    }

    ##################################################################

    $sth->finish;

    ();
}
sub load_constraint_foreign_key {        # ;
    my ($self, $catalog, @schemas) = @_;

    my $column_list = [];
    my $refcolumn_list = [];
    my $sth = $self->execute ($self->_query_constraint_foreign_key (@schemas));

    while (my $row = $sth->fetchrow_hashref) {
        push @$column_list,    lcws $row->{column_name};
        push @$refcolumn_list, lcws $row->{refcolumn_name};

        if ($row->{colno} == $row->{colcount}) {
            my $constr = $catalog->add (table => (
                schema => lcws $row->{table_schema},
                name   => lcws $row->{table_name}
            ))->add (foreign_key => (
                name             => lcws $row->{constraint_name},
                referenced_table => $catalog->add (table => (
                    schema => lcws $row->{reftable_schema},
                    name   => lcws $row->{reftable_name}
                )),
                referencing_column_list => $column_list,
                referenced_column_list  => $refcolumn_list,
                update_rule => $row->{update_rule},
                delete_rule => $row->{delete_rule},
            ));

            $column_list = [];
            $refcolumn_list = [];
        };
    }
}


######################################################################
######################################################################
sub load_constraint_check {              # ; TODO;
}


######################################################################
######################################################################

package SQL::Admin::Driver::DB2::DBI;

1;

