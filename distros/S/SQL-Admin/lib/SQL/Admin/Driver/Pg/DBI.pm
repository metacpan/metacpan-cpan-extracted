
package SQL::Admin::Driver::Pg::DBI;
use base qw( SQL::Admin::Driver::Base::DBI );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

use SQL::Admin::Driver::Pg::Parser;

######################################################################

our %TYPE_MAP = (
    smallint   => 'int2',  int2 => 'int2',
    integer    => 'int4',  int4 => 'int4',
    bigint     => 'int8',  int8 => 'int8',
    vargraphic => 'varchar',
    varchar    => 'varchar',
    character  => 'character',
    decimal    => 'decimal',
    numeric    => 'decimal',
    float8     => 'double',
    float4     => 'real',
    date       => 'date',
    time       => 'time',
    timestamp  => 'timestamp',
);

our %TYPE_WITH_SIZE = (
    varchar    => 1,
    character  => 1,
    vargraphic => 2,
    decimal    => 1,
    numeric    => 1,
);

our %TYPE_WITH_SCALE = (
    decimal    => 1,
    numeric    => 1,
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
    $self->{parser} ||= SQL::Admin::Driver::Pg::Parser->new;
}


######################################################################
######################################################################
sub load {                               # ;
    my ($self, $catalog, @schemas) = @_;

    local $self->{TCM};
    local $self->{pg_map} = {};

    $self->SUPER::load ($catalog, map lc, @schemas);
    # shift->SUPER::load (map ref ($_) ? lc : $_, @_);
}


######################################################################
######################################################################
sub _list_sequence {                     # ;
    my ($self, $catalog) = @_;

    ();
}


######################################################################
######################################################################
sub _query_table {                       # ;
    my ($self, @schemas) = @_;

    $self->sqla->select (
        [ 'pg_class t, pg_namespace n' ],
        [
            'n.nspname as table_schema',
            't.relname as table_name',
        ],
        {
            'n.nspname' => ( @schemas ? \ @schemas : { 'not in' => [ 'pg_catalog', 'information_schema' ] }),
            't.relkind' => 'r',
            't.relnamespace' => \ ' = n.oid',
        },
    );
}


######################################################################
######################################################################
sub _query_table_column {                # ;
    my ($self, @schemas) = @_;

    $self->sqla->select (
        [ join ', ', (
            'pg_attribute c',
            'pg_class t',
            'pg_namespace n',
            'pg_type y',
        )],
        [
            't.oid     as table_oid',
            'n.nspname as table_schema',
            't.relname as table_name',
            'c.attname as column_name',
            'y.typname as data_type',
            'c.attnotnull as not_null',
            'case when c.atttypmod > 0 then
                case when y.typname = \'varchar\' then c.atttypmod - 4
                     when y.typname = \'numeric\' then atttypmod / 65536
                end
             end as data_type_size',
            'case when c.atttypmod > 0 then
                case when y.typname = \'numeric\' then atttypmod % 65536 - 4
                end
             end as data_type_scale',
            'attnum as column_number'
        ],
        {
            'n.nspname' => ( @schemas ? \ @schemas : { 'not in' => [ 'pg_catalog', 'information_schema' ] }),
            't.relkind' => 'r',
            't.relnamespace' => \ ' = n.oid',
            'c.attrelid'     => \ ' = t.oid',
            'c.attnum'       => { '>', 0 },
            'c.atttypid'     => \ ' = y.oid',
            'c.attisdropped' => 'f',
        },
        [ 'table_schema, table_name, attnum' ],
    );
}


######################################################################
######################################################################
sub _query_table_column_default {        # ;
    my ($self, @schemas) = @_;

    $self->sqla->select (
        [ 'pg_attrdef'],
        [
            'adrelid as table_oid',
            'adnum   as column_number',
            'adsrc as default_clause',
        ],
        {
            # ignore sequences (for now)
            'adsrc' => { 'not like' => 'nextval%' },
        },
    );
}


######################################################################
######################################################################
sub _query_table_column_autoincrement {  # ;
    my ($self, @schemas) = @_;

    $self->sqla->select (
        [
            'pg_depend    d',
            'pg_class     S',
            'pg_namespace N',
        ],
        [
            'd.refobjid    as table_oid',
            'd.refobjsubid as column_number',
            'N.nspname     as sequence_schema',
            'S.relname     as sequence_name',
        ],
        {
            'd.objid'        => \ ' = S.oid',
            'd.deptype'      => 'a',
            'S.relkind'      => 'S',
            'S.relnamespace' => \ ' = N.oid',
        },
    );
}


######################################################################
######################################################################
sub _query_constraint_primary_key {      # ;
    my ($self, @schemas) = @_;

    $self->sqla->select (
        [ 'pg_constraint' ],
        [
            'conrelid as table_oid',
            'conkey   as column_list',
        ],
        {
            contype => 'p',
        },
    );

}


######################################################################
######################################################################
sub _query_constraint_unique {           # ;
    my ($self, @schemas) = @_;

    $self->sqla->select (
        [ 'pg_constraint' ],
        [
            'conrelid as table_oid',
            'conkey   as column_list',
        ],
        {
            contype => 'u',
        },
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
sub __load_index {                       # ;
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
sub _load_tcm {                          # ;
    my ($self, @schemas) = @_;

    $self->{TCM} ||= do {
        my $map = {};

        my $sth = $self->execute ($self->_query_table_column (@schemas));
        while (my $row = $sth->fetchrow_hashref) {
            my $oid = $row->{table_oid};
            $map->{$oid} ||= {
                -name   => lcws $row->{table_name},
                -schema => lcws $row->{table_schema},
                -column_list => [],
            };
            $row->{column_name} = lcws $row->{column_name};
            $map->{$oid}{$row->{column_number}} = $row->{column_name};
            push @{ $map->{$oid}{-column_list} }, $row;
        }
        $sth->finish;

        $map;
    };
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
sub load_table_column {                  # ;
    my ($self, $catalog, @schemas) = @_;
    my $tcm = $self->_load_tcm (@schemas);

    while (my ($oid, $def) = each %$tcm) {
        my $table = $catalog->add (table => (
            schema => $def->{-schema},
            name   => $def->{-name},
        ));

        for my $row (@{ $def->{-column_list} }) {
            my $column = $table->add (column => (
                name => lcws $row->{column_name}
            ));

            my $type = lcws $row->{data_type};
            die "Unknown data type: $def->{-schema}.$def->{-name}.$row->{column_name}: $type\n"
              unless exists  $TYPE_MAP{ $type };

            $column->type ({
                type => $TYPE_MAP{ $type },
                (map +(size  => $_ * $row->{data_type_size}),  grep $_, $TYPE_WITH_SIZE{ $type }),
                (map +(scale =>      $row->{data_type_scale}), grep $_, $TYPE_WITH_SCALE{ $type }),
            });

            ##########################################################

            $column->not_null (1)
              if $row->{not_null};

            $column->default ($self->parser->default_clause_value ($_))
              for grep defined, $row->{default};
        }
    }

    ##################################################################

    ();
}


######################################################################
######################################################################
sub load_table_column_default {          # ;
    my ($self, $catalog, @schemas) = @_;
    my $tcm = $self->_load_tcm (@schemas);

    my $sth = $self->execute ($self->_query_table_column_default (@schemas));
    while (my $row = $sth->fetchrow_hashref) {
        next unless my $table = $tcm->{ $row->{table_oid} };

        my $column = $catalog->add (table => (
            schema => $table->{-schema},
            name   => $table->{-name},
        ))->add (column => (
            name   => $table->{ $row->{column_number} },
        ));

        $column->default ($self->parser->default_clause_value ($_))
          for grep defined, $row->{default_clause};
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_table_column_autoincrement {    # ;
    my ($self, $catalog, @schemas) = @_;
    my $tcm = $self->_load_tcm (@schemas);

    my $sth = $self->execute ($self->_query_table_column_autoincrement);
    while (my $row = $sth->fetchrow_hashref) {
        next unless my $table = $tcm->{ $row->{table_oid} };

        my $column = $catalog->add (table => (
            schema => $table->{-schema},
            name   => $table->{-name},
        ))->add (column => (
            name   => $table->{ $row->{column_number} },
        ));

        $column->autoincrement (1);
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_constraint_primary_key {        # ;
    my ($self, $catalog, @schemas) = @_;
    my $tcm = $self->_load_tcm (@schemas); # tcm = table column map

    my $sth = $self->execute ($self->_query_constraint_primary_key);
    while (my $row = $sth->fetchrow_hashref) {
        next unless my $table = $tcm->{ $row->{table_oid} };

        # primary key is a list of column indexes
        $catalog->add (table => (
            schema => $table->{-schema},
            name   => $table->{-name},
        ))->add (primary_key => (
            column_list => [ map $table->{$_}, @{ $row->{column_list} } ],
        ));
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub load_constraint_unique {             # ;
    my ($self, $catalog, @schemas) = @_;
    my $tcm = $self->_load_tcm (@schemas); # tcm = table column map

    my $sth = $self->execute ($self->_query_constraint_unique);
    while (my $row = $sth->fetchrow_hashref) {
        next unless my $table = $tcm->{ $row->{table_oid} };

        # primary key is a list of column indexes
        $catalog->add (table => (
            schema => $table->{-schema},
            name   => $table->{-name},
        ))->add (unique => (
            column_list => [ map $table->{$_}, @{ $row->{column_list} } ],
        ));
    }

    ##################################################################

    $sth->finish;

    ();
}


######################################################################
######################################################################
sub _load_constraint_foreign_key {       # ;
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
sub _load_constraint_check {             # ; TODO;
}


######################################################################
######################################################################

package SQL::Admin::Driver::Pg::DBI;

1;

__END__

