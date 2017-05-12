package MySQL::Util::Data::Create;

use Moose::Role;
use Data::Dumper;
use SQL::Beautify;
use Symbol::Util 'delete_sub';
use Smart::Args;
use feature 'state';
use List::MoreUtils 'uniq';
use Carp 'croak';
use Config::General;

=head1 NAME

MySQL::Util::Data::Create - A Moose::Role for MySQL::Util.  Do not call this
                            directly!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

use MySQL::Util;

my $util = MySQL::Util->new(...);
    
$util->create_data(
            table    => 'sometable',
            rows     => 500,
            defaults => {
                my_id        => 10,
                enabled_flag => 1
        });

=head1 SUBROUTINES/METHODS

=head2 create_data( %args )

Creates X number of rows in the specified table.  Columns are populated with
random data if it can't be derived through auto-increment, foreign-keys, or
enum.  If defaults are provided they are used in favor over random values.

=head3 Arguments:

=over

=item table

name of table you want to create data in

=item rows

how many rows to create

=item defaults (optional)

A hashref that contains default data values for columns that may be
encountered.  If a column default is specified for which no column
exists, it will be ignored.  Each key is the column name and
each value is the default value you wish to use.

=back

=head3 Examples:

    $util->create_data(
        table     => 'mytable',
        rows => 50,
        defaults  => {
                        id => 44,
                        age => 25
                    } );

    $util->create_data(
        table     => 'students',
        rows => 1000
    );
    
=cut

has _create_cache => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    default  => sub { {} },
);

has _table_aliases => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    default  => sub { {} },
);

has _last_table_alias_num => (
    is       => 'rw',
    isa      => 'Int',
    required => 0,
    default  => 0
);

sub _get_table_alias {
    args

        # required
        my $self  => 'Object',
        my $table => 'Str';

    $table = $self->_fq( table => $table, fq => 1 );

    my $href = $self->_table_aliases;

    if ( exists $href->{$table} ) {
        return $href->{$table};
    }

    my $new_num   = $self->_last_table_alias_num + 1;
    my $new_alias = "t$new_num";

    $href->{$table} = $new_alias;
    $self->_table_aliases($href);
    $self->_last_table_alias_num($new_num);

    return $new_alias;
}

sub _create_factory_method {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef';

    my $method = 'create_factory_data';

    if ( MySQL::Util->can($method) ) {
        delete_sub "MySQL::Util::$method";
    }

    my $col_rules = $self->_get_column_rules(
        table         => $table,
        col_data_href => $col_data_href
    );
    $self->_verbose( "col_rules:\n" . Dumper($col_rules) );

    my $factory = DBIx::DataFactory->new( { dbh => $self->_dbh } );

    # what to do with $fm if anything?
    my $fm = $factory->create_factory_method(
        method                => $method,
        table                 => $table,
        install_package       => 'MySQL::Util',
        auto_inserted_columns => $col_rules
    );

    return $method;
}

sub _parse_fq_col {
    args_pos

        # required
        my $self => 'Object',
        my $col  => 'Str';

    my @a = split( /\./, $col );

    confess "unable to parse column name: $col" if @a > 3;

    if ( @a == 3 ) {
        return @a;
    }
    elsif ( @a == 2 ) {
        return ( undef, @a );
    }

    return ( '', '', $a[0] );
}

sub _apply_defaults {
    args

        # required
        my $self  => 'Object',
        my $table => 'Str',

        # optional
        my $defaults => { isa => 'HashRef', default => {}, optional => 1 },
        my $conf     => { isa => 'Str|Undef', optional => 1};

    my $defaults_href;

    if ($conf) {
        my $config = new Config::General($conf);
        my %config = $config->getall;

        foreach my $col ( keys %config ) {
            my $val = $config{$col};

            my ( $dbname, $t, $c ) = $self->_parse_fq_col($col);
            if ( $t eq $table ) {
                $defaults_href->{$c} = $val;
            }
            else {
                $defaults_href->{$col} = $val;
            }
        }
    }

    foreach my $col ( keys %$defaults ) {
        # command line overrides conf file values
        my ( $dbname, $t, $c ) = $self->_parse_fq_col($col);
        if ( $t eq $table ) {
            $defaults_href->{$c} = $defaults->{$col};
        }
        else {
            $defaults_href->{$col} = $defaults->{$col};
        }
    }

    return $defaults_href;
}

sub create_data {
    args

        # required
        my $self  => 'Object',
        my $table => 'Str',
        my $rows  => 'Int',

        # optional
        my $defaults => { isa => 'HashRef', default  => {}, optional => 1 },
        my $conf     => { isa => 'Str',     optional => 1 };

    my $defaults_href = $self->_apply_defaults(
        table    => $table,
        defaults => $defaults,
        conf     => $conf
    );

    # table MUST be in the current schema
    if ( $table =~ /^(\w+)\.(\w+)/ ) {
        if ( $1 ne $self->_schema ) {
            confess "table $table is not in the current schema";
        }
    }

    # convert null to undef
    foreach my $col_name ( keys %$defaults_href ) {
        if ( $defaults_href->{$col_name} =~ /^null$/i ) {
            $defaults_href->{$col_name} = undef;
        }
    }

    my $method;

    for ( my $i = 0; $i < $rows; $i++ ) {
        my %col_data = %$defaults_href;
        $self->_verbose( "default data\n" . Dumper( \%col_data ) );

        $self->_get_pk_data( table => $table, col_data_href => \%col_data );
        $self->_verbose( "after pk data\n" . Dumper( \%col_data ) );

        $self->_get_ak_data( table => $table, col_data_href => \%col_data );
        $self->_verbose( "after ak data\n" . Dumper( \%col_data ) );

        $self->_get_fk_data( table => $table, col_data_href => \%col_data );
        $self->_verbose( "after fk data\n" . Dumper( \%col_data ) );

        $self->_get_enum_data( table => $table, col_data_href => \%col_data );
        $self->_verbose( "after enum data\n" . Dumper( \%col_data ) );

        if ( !defined($method) ) {
            $method = $self->_create_factory_method(
                table         => $table,
                col_data_href => \%col_data
            );
        }

        my $values = $self->$method(%col_data);
        confess "got undef?" if !$values;
    }

    return $rows;
}

sub _get_table2alias_lookup {
    args

        # required
        my $self            => 'Object',
        my $table           => 'Str',
        my $constraint_name => 'Str',

        # optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    $table = $self->_fq( table => $table, fq => $fq );

    my %tables;

    my $i        = 1;
    my $con_aref = $self->get_constraints($table)->{$constraint_name};

    foreach my $con_col_href (@$con_aref) {
        my $col_name = $con_col_href->{COLUMN_NAME};
        my $ref_table;

        if ( $self->is_fk_column( table => $table, column => $col_name ) ) {
            my $fk_col_href = $self->_get_fk_column(
                table  => $table,
                column => $col_name
            );

            my %parm = (
                table => $fk_col_href->{REFERENCED_TABLE_NAME},
                fq    => $fq
            );

            if ($fq) {
                $parm{schema} = $fk_col_href->{REFERENCED_TABLE_SCHEMA};
            }

            $ref_table = $self->_fq( %parm, fq => $fq );
        }
        else {
            $ref_table = $self->_fq( table => $table, fq => $fq );
        }

        if ( !$tables{$ref_table} ) {
            my $alias = 't' . $i;
            $tables{$ref_table} = $alias;
            $i++;
        }
    }

    return \%tables;
}

sub _get_where_not_exists {
    args

        # required
        my $self            => 'Object',
        my $table           => 'Str',
        my $constraint_name => 'Str',
        my $alias_href      => 'HashRef',

        # optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    $table = $self->_fq( table => $table, fq => $fq );

    my $con_aref = $self->get_constraints($table)->{$constraint_name};
    my @where;

    foreach my $con_href (@$con_aref) {

        my $schema   = $con_href->{CONSTRAINT_SCHEMA};
        my $col_name = $con_href->{COLUMN_NAME};

        my $ref_alias;
        my $ref_col;

        if ( $self->is_fk_column( table => $table, column => $col_name ) ) {
            my $con_fk_href = $self->_get_fk_column(
                table  => $table,
                column => $col_name
            );

            my $ref_schema = $con_fk_href->{REFERENCED_TABLE_SCHEMA};
            my $ref_table  = $con_fk_href->{REFERENCED_TABLE_NAME};
            my $joined     = join '.', ( $ref_schema, $ref_table );

            $ref_alias = $alias_href->{$joined};
            $ref_col   = $con_fk_href->{REFERENCED_COLUMN_NAME};
        }
        else {
            $ref_alias = $alias_href->{$table};
            $ref_col   = $col_name;
        }

        push @where, "x.$col_name = $ref_alias.$ref_col";
    }

    my $where = join " and\n", @where;

    return qq{
        select *
        from $table x
        where $where
        } if $where;
}

sub _get_where_clause {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef',
        my $alias_href    => 'HashRef';

    #
    # apply any known data to columns for tables in the from clause
    #
    my @where;

    foreach my $table ( keys %$alias_href ) {
        my $desc_aref = $self->describe_table($table);

        foreach my $column_href (@$desc_aref) {
            my $col_name = $column_href->{FIELD};

            if ( exists $col_data_href->{$col_name} ) {

                my $table_alias = $alias_href->{$table};
                my $val         = $col_data_href->{$col_name};

                if ($self->_column_exists(
                        table  => $table,
                        column => $col_name
                    )
                    )
                {
                    if ( !defined $val ) {
                        if ($self->is_column_nullable(
                                table  => $table,
                                column => $col_name
                            )
                            )
                        {
                            push( @where, "$table_alias.$col_name is NULL" );
                        }
                        else {
                            confess
                                "tried to set a non-nullable column to null ($table.$col_name)";
                        }
                    }
                    else {
                        push( @where, "$table_alias.$col_name = $val" );
                    }
                }
            }
        }
    }

    return join ' and ', @where;
}

sub _is_table_empty {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef';

    my $alias_href = { $table => 't1' };

    my $from = $self->_get_from_clause($alias_href);

    my $where = $self->_get_where_clause(
        table         => $table,
        col_data_href => $col_data_href,
        alias_href    => $alias_href
    );

    my $sql = qq{
        select count(*)
        from $from
        };

    if ($where) {
        $sql .= " where $where ";
    }

    my $cnt = $self->_dbh->selectrow_arrayref($sql)->[0];

    if ( !$cnt ) {
        return 1;
    }

    return 0;
}

sub _get_from_clause {
    args_pos

        # required
        my $self       => 'Object',
        my $alias_href => 'HashRef';

    my @tables;
    foreach my $t ( keys %$alias_href ) {
        push( @tables, "$t $alias_href->{$t}" );
    }

    return join ', ', @tables;
}

sub _get_func_cache {
    args

        # required
        my $self => 'Object';

    my $func = ( caller(1) )[3];

    my $c = $self->_create_cache;

    if ( !exists $c->{$func} ) {
        $c->{$func} = {};
        $self->_create_cache($c);
    }

    return $c->{$func};
}

sub _get_constraint_non_fk_columns {
    args

        # required
        my $self            => 'Object',
        my $table           => 'Str',
        my $constraint_name => 'Str';

    my $c = $self->_get_func_cache;

    if ( defined $c->{$table}->{$constraint_name} ) {
        return @{ $c->{$table}->{$constraint_name} };
    }

    # $hashref->{constraint_name}->[ { col1 }, { col2 } ]
    #
    #Hash elements for each column:
    #
    #    CONSTRAINT_SCHEMA
    #    CONSTRAINT_TYPE
    #    COLUMN_NAME
    #    ORDINAL_POSITION
    #    POSITION_IN_UNIQUE_CONSTRAINT
    #    REFERENCED_COLUMN_NAME
    #    REFERENCED_TABLE_SCHEMA
    #    REFERENCED_TABLE_NAME

    my @columns;

    my $con_aref
        = $self->get_constraint( table => $table, name => $constraint_name );

    foreach my $col_href (@$con_aref) {

        my $col_name = $col_href->{COLUMN_NAME};

        if ( !$self->is_fk_column( table => $table, column => $col_name ) ) {
            push( @columns, $col_name );
        }
    }

    $c->{$table}->{$constraint_name} = \@columns;
    return @columns;
}

sub _get_uniq_constraint_data_sql {
    args

        # required
        my $self            => 'Object',
        my $table           => 'Str',
        my $col_data_href   => 'HashRef',
        my $constraint_name => 'Str',

        #optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    my $alias_href = $self->_get_table2alias_lookup(
        table           => $table,
        constraint_name => $constraint_name,
        fq              => 1
    );

    my $tables = $self->_get_from_clause($alias_href);

    my $cols = $self->_get_select_clause(
        table           => $table,
        constraint_name => $constraint_name,
        alias_href      => $alias_href,
        fq              => $fq
    );

    my $where = $self->_get_where_not_exists(
        table           => $table,
        constraint_name => $constraint_name,
        alias_href      => $alias_href
    );

    my $extra_criteria = $self->_get_where_clause(
        table         => $table,
        col_data_href => $col_data_href,
        alias_href    => $alias_href,
    );
    $extra_criteria = " and $extra_criteria " if $extra_criteria;

    # TODO: implement this for randomness:
    #
    #SELECT name
    #  FROM random AS r1 JOIN
    #       (SELECT (RAND() *
    #                     (SELECT MAX(id)
    #                        FROM random)) AS id)
    #        AS r2
    # WHERE r1.id >= r2.id
    # ORDER BY r1.id ASC
    # LIMIT 1
    #

    my $sql = qq{
            select distinct $cols
            from $tables
            where not exists ($where)
                $extra_criteria
            limit 1
        };

    return $sql;
}

sub _get_uniq_constraint_data {
    args

        #required
        my $self            => 'Object',
        my $table           => 'Str',
        my $col_data_href   => 'HashRef',
        my $constraint_name => 'Str',

        #optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    $table = $self->_fq( table => $table, fq => $fq );

    if (!$self->_get_constraint_non_fk_columns(
            table           => $table,
            constraint_name => $constraint_name
        )
        )
    {

        #
        # the data for each column, in the uniq constraint, has to come from
        # a reference table
        #
        my $sql = $self->_get_uniq_constraint_data_sql(
            table           => $table,
            col_data_href   => $col_data_href,
            constraint_name => $constraint_name,
            fq              => $fq
        );
        $self->_verbose_sql($sql);

        my $href = $self->_dbh->selectrow_hashref($sql);
        if ( !$href ) {
            if ( $self->is_self_referencing( table => $table ) ) {
                confess "self referencing tables not implemented";
            }
            elsif (
                $self->_is_table_empty(
                    table         => $table,
                    col_data_href => $col_data_href
                )
                )
            {

                # let it go through
            }
            else {
                confess "not enough data in parent table(s) to create a "
                    . "new row due to constraint $constraint_name";
            }
        }
        else {
            foreach my $col ( keys %$href ) {

                if ( !exists $col_data_href->{ lc $col } ) {

                    $col_data_href->{ lc $col } = $href->{$col};
                }
            }
        }
    }
}

sub _join_tables {
    args

        # required
        my $self         => 'Object',
        my $child_table  => 'Str',
        my $parent_table => 'Str';

    #
    # debug stuff
    #
    shift;
    $self->_verbose( "enter:\n" . Dumper( \@_ ) );

    $child_table = $self->_fq( table => $child_table, fq => 1 );
    my $child_alias = $self->_get_table_alias( table => $child_table );

    $parent_table = $self->_fq( table => $parent_table, fq => 1 );

    my $join_sql;
    my $fks_href = $self->get_fk_constraints($child_table);

    foreach my $fk_name ( keys %$fks_href ) {
        my $fk_aref    = $fks_href->{$fk_name};
        my $ref_table  = $fk_aref->[0]->{REFERENCED_TABLE_NAME};
        my $ref_schema = $fk_aref->[0]->{REFERENCED_TABLE_SCHEMA};
        my $ref_fq     = $self->_fq(
            table  => $ref_table,
            schema => $ref_schema,
            fq     => 1
        );

        $self->_verbose("ref_fq=$ref_fq\nparent_table=$parent_table");

        if ( $ref_fq eq $parent_table ) {
            my $ref_alias = $self->_get_table_alias( table => $ref_fq );

            foreach my $col_href (@$fk_aref) {
                $join_sql .= sprintf( "%s.%s = %s.%s\n",
                    $ref_alias,   $col_href->{REFERENCED_COLUMN_NAME},
                    $child_alias, $col_href->{COLUMN_NAME} );
            }
        }
    }

    $self->_verbose($join_sql);
    return $join_sql;
}

sub _build_select_clause {
    args

        # required
        my $self    => 'Object',
        my $table   => 'Str',
        my $fk_tree => 'HashRef';

    #
    # debug stuff
    #
    shift;
    $self->_verbose( "enter:\n" . Dumper( \@_ ) );

    $table = $self->_fq( table => $table, fq => 1 );

    my @select;

    my $fks_href = $self->get_fk_constraints($table);

    foreach my $fk_name ( keys %$fks_href ) {
        my $fk_aref = $fks_href->{$fk_name};

        my $ref_table_fq = $self->_fq(
            table  => $fk_aref->[0]->{REFERENCED_TABLE_NAME},
            schema => $fk_aref->[0]->{REFERENCED_TABLE_SCHEMA},
            fq     => 1
        );

        if ( exists $fk_tree->{$ref_table_fq} ) {
            my $ref_alias = $self->_get_table_alias( table => $ref_table_fq );

            foreach my $col_href (@$fk_aref) {

                push( @select,
                    "$ref_alias." . $col_href->{REFERENCED_COLUMN_NAME} );
            }
        }
    }

    my $select = join ', ', @select;
    $self->_verbose("return:\n$select");
    return $select;
}

sub _build_from_clause {
    args

        # required
        my $self    => 'Object',
        my $table   => 'Str',
        my $fk_tree => 'HashRef',

        # optional
        my $depth => { isa => 'Int', optional => 1, default => 0 };

    #
    # debug stuff
    #
    shift;
    $self->_verbose( "enter:\n" . Dumper( \@_ ) );

    my %from;

    if ( !$depth ) {
        foreach my $parent_table ( keys %$fk_tree ) {

            if ( scalar keys %{ $fk_tree->{$parent_table} } ) {

                my %tmp = $self->_build_from_clause(
                    table   => $parent_table,
                    fk_tree => $fk_tree->{$parent_table},
                    depth   => $depth + 1
                );
                foreach my $key ( keys %tmp ) {
                    push( @{ $from{$key} }, @{ $tmp{$key} } );
                }
            }
            else {
                my $alias = $self->_get_table_alias( table => $parent_table );
                $from{"$parent_table $alias"} = [];
            }
        }
    }
    else {
        foreach my $parent_table ( keys %$fk_tree ) {

            my $join = $self->_join_tables(
                child_table  => $table,
                parent_table => $parent_table
            );

            my $alias = $self->_get_table_alias( table => $table );
            if ( !$from{"$table $alias"} ) {
                $from{"$table $alias"} = [];
            }

            $alias = $self->_get_table_alias( table => $parent_table );
            push( @{ $from{"$parent_table $alias"} }, $join );

            if ( scalar keys %{ $fk_tree->{$parent_table} } ) {

                my %tmp = $self->_build_from_clause(
                    table   => $parent_table,
                    fk_tree => $fk_tree->{$parent_table},
                    depth   => $depth + 1
                );
                foreach my $key ( keys %tmp ) {
                    push( @{ $from{$key} }, @{ $tmp{$key} } );
                }
            }
        }
    }

    $self->_verbose( "return:\n" . Dumper( \%from ) );
    return %from;
}

sub _build_where_clause {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $fk_tree       => 'HashRef',
        my $col_data_href => 'HashRef',

        # optional
        my $depth => { isa => 'Int', optional => 1, default => 0 };

    #
    # debug stuff
    #
    shift;
    $self->_verbose( "enter:\n" . Dumper( \@_ ) );

    my @where;

    if ($depth) {
        my $desc = $self->describe_table($table);
        my $alias = $self->_get_table_alias( table => $table );

        foreach my $col_href (@$desc) {
            my $col_name = lc $col_href->{FIELD};

            if ( exists $col_data_href->{$col_name} ) {
                push( @where,
                    "$alias.$col_name = $col_data_href->{$col_name}" );

                #            delete $col_data_href->{$col_name};
            }
        }
    }

    foreach my $parent_table ( keys %$fk_tree ) {
        push(
            @where,
            $self->_build_where_clause(
                table         => $parent_table,
                fk_tree       => $fk_tree->{$parent_table},
                col_data_href => $col_data_href,
                depth         => $depth + 1
            )
        );
    }

    $self->_verbose("@where");
    return @where;
}

sub _get_fk_data {
    args my $self         => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef';

    my $fk_tree = $self->_get_fk_tree(
        table               => $table,
        remaining_data_href => {%$col_data_href},

    );
    $self->_verbose( "fk_tree:\n " . Dumper($fk_tree) );

    if ( scalar keys %$fk_tree ) {

        my $select = $self->_build_select_clause(
            table   => $table,
            fk_tree => $fk_tree
        );
        $self->_verbose($select);

        my %from = $self->_build_from_clause(
            table   => $table,
            fk_tree => $fk_tree
        );
        my $alias = $self->_get_table_alias( table => $table );
        my $from = '';

        my %depth_chart;

        foreach my $t ( keys %from ) {
            my ( $tname, $talias ) = split( /\s+/, $t );
            my $dep = $self->get_depth($tname);
            $depth_chart{$dep}->{$t} = 1;
        }

        my @from_tables;
        my @no_join_tables;

        foreach my $depth ( sort { $b <=> $a } keys(%depth_chart) ) {

            my $ptr = $depth_chart{$depth};

            foreach my $t ( keys %$ptr ) {

                #    foreach my $t ( keys %from ) {
                my @a = @{ $from{$t} };
                @a = uniq @a;
                if ( !@a ) {
                    push( @no_join_tables, $t );
                }
                else {
                    $from .= "inner join $t on " . join( ' and ', @a );
                    $from .= "\n";
                }

                push( @from_tables, $t );
            }
        }
        my $tmp = $from;
        $from = join( "\ninner join\n", @no_join_tables );
        $from .= "\n$tmp" if $tmp;
        $self->_verbose($from);

        my @where = $self->_build_where_clause(
            table         => $table,
            fk_tree       => $fk_tree,
            col_data_href => {%$col_data_href}
        );
        my $where = join( ' and ', uniq @where );
        $self->_verbose($where);

        my $sql = qq{
            select
                $select
            from
                $from
                };
        $sql .= qq{
            where
                $where
                } if $where;
        $sql .= q{
            limit 1
        };
        $self->_verbose_sql($sql);

        my $href = $self->_dbh->selectrow_hashref($sql);
        if ( !$href ) {
            my $msg
                = "not enough data in one (or more) parent table(s) to create "
                . "a new row in table $table\n\nparent tables:\n";

            foreach my $t ( sort uniq @from_tables ) {
                $msg .= "\t$t\n\n";
            }

            croak $msg;
        }
        else {
            foreach my $col ( keys %$href ) {
                if ( !exists $col_data_href->{ lc $col } ) {
                    if ( !defined( $href->{$col} ) ) {
                        if (!$self->is_column_nullable(
                                table  => $table,
                                column => $col
                            )
                            )
                        {
                            confess
                                "tried to set a non-nullable column to null ($table.$col)";
                        }
                    }

                    $col_data_href->{ lc $col } = $href->{$col};
                }
            }
        }
    }

    $self->_convert_missing_fk_cols_to_undef(
        table         => $table,
        col_data_href => $col_data_href
    );
}

#
# find foreign key _tables_ that we are missing data for return in a
# hierarchical structure
#
sub _get_fk_tree {
    args

        # required
        my $self                => 'Object',
        my $remaining_data_href => 'HashRef',
        my $table               => 'Str',

        # optional
        my $depth => { isa => 'Int', optional => 1, default => 0 };

    my $node = {};

    #
    # debug stuff
    #
    my @a = @_;
    shift @a;
    $self->_verbose( Dumper( \@a ) );

#
# all data qualifications satisfied
#
#    return
#        if
#        keys %$remaining_data_href == 0;  # no reason to continue up the chain

    #
    # does this table have any columns for which we have data left?
    #
    my $hit;

    if ( $depth != 0 ) {    # skip root table

        my $desc = $self->describe_table($table);
        foreach my $col_href (@$desc) {

            my $col_name = $col_href->{FIELD};

            if ( exists( $remaining_data_href->{$col_name} ) ) {

                # we have a hit
                delete $remaining_data_href->{$col_name};
                $self->_verbose("removed col $col_name");
                $hit++;
            }

            #     if ( keys %$remaining_data_href == 0 ) {
            #         return $node;
            #     }
        }
    }

    #
    # if we get here we are still in search of columns to match with
    # remaining_data_href.  through recursion, keep walking the foreign keys
    # up the hierarchy.
    #
    my %seen;

    my $fks_href = $self->get_fk_constraints($table);

    foreach my $fk_name ( keys %$fks_href ) {
        $self->_verbose("fk=$fk_name");

        my $fk_aref = $fks_href->{$fk_name};

        my $col_href = shift @$fk_aref;    # only need one column from fk

        my $ref_table  = $col_href->{REFERENCED_TABLE_NAME};
        my $ref_schema = $col_href->{REFERENCED_TABLE_SCHEMA};
        my $ref_fq     = $self->_fq(
            table  => $ref_table,
            schema => $ref_schema,
            fq     => 1
        );

        if ($self->is_self_referencing(
                table => $ref_fq,
                name  => $fk_name
            )
            )
        {
            $self->_verbose("$fk_name is self referencing");
            next;
        }

        #  next if $seen{$ref_fq};
        #  $seen{$ref_fq} = 1;

        my $href = $self->_get_fk_tree(
            remaining_data_href => {%$remaining_data_href},
            table               => $ref_fq,
            depth               => $depth + 1
        );
        if ( $href or $depth == 0 ) {
            $hit++;    # if a parent has a hit, we automatically do too
            if ( !$href ) {
                $href = {};
            }

            $node->{$ref_fq} = $href;
        }
    }

    $self->_verbose( Dumper($node) );
    if ($hit) {
        return $node;
    }

    return;
}

sub _convert_missing_fk_cols_to_undef {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef';

    #
    # debugging stuff
    #
    state $cnt++;
    shift @_;
    $self->_verbose( "enter\n\nargs:\n" . Dumper(@_), $cnt );

    foreach my $col ( $self->get_fk_column_names( table => $table ) ) {
        if ( !exists $col_data_href->{$col} ) {
            if (!$self->is_column_nullable(
                    table  => $table,
                    column => $col
                )
                )
            {
                confess
                    "tried to set a non-nullable column to null ($table.$col)\n\n"
                    . Dumper($col_data_href);
            }

            $col_data_href->{$col} = undef;
        }
    }
}

sub _get_ak_data {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef',

        #optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    $table = $self->_fq( table => $table, fq => $fq );

    if ( $self->has_ak($table) ) {

        my $aks_href = $self->get_ak_constraints($table);

        foreach my $ak_name ( keys %$aks_href ) {

            $self->_get_uniq_constraint_data(
                table           => $table,
                col_data_href   => $col_data_href,
                constraint_name => $ak_name
            );
        }
    }
}

sub _get_pk_data {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef',

        # optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    $table = $self->_fq( table => $table, fq => $fq );

    if ( $self->has_pk($table) and !$self->is_pk_auto_inc($table) ) {

        $self->_get_uniq_constraint_data(
            table           => $table,
            col_data_href   => $col_data_href,
            constraint_name => $self->get_pk_name($table)
        );
    }

    return;
}

sub _get_column_rules {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef';

    state $cnt++;
    shift @_;
    $self->_verbose( "enter($cnt)\nargs:\n\n" . Dumper(@_), $cnt );

    my %rules;

    #    $arrayref->[ { col1 }, { col2 } ]
    #
    #Hash elements for each column:
    #
    #	DEFAULT
    #	EXTRA
    #	FIELD
    #	KEY
    #	NULL
    #	TYPE
    #mysql> DESCRIBE pet;
    #+---------+-------------+------+-----+---------+-------+
    #| Field   | Type        | Null | Key | Default | Extra |
    #+---------+-------------+------+-----+---------+-------+
    #| name    | varchar(20) | YES  |     | NULL    |       |
    #| owner   | varchar(20) | YES  |     | NULL    |       |
    #| species | varchar(20) | YES  |     | NULL    |       |
    #| sex     | char(1)     | YES  |     | NULL    |       |
    #| birth   | date        | YES  |     | NULL    |       |
    #| death   | date        | YES  |     | NULL    |       |
    #+---------+-------------+------+-----+---------+-------+

    foreach my $col ( @{ $self->describe_table($table) } ) {
        $self->_verbose("col = $col");

        my $name = $col->{FIELD};
        my $type = $col->{TYPE};
        my $size;

        next if exists $col_data_href->{$name};
        next if $col->{EXTRA} =~ /auto/;
        next
            if $self->is_fk_column( table => $table, column => $col );

        if ( $type =~ /varchar\((\d+)\)/ ) {
            $type = 'Str';
            $size = int( $1 / 2 );
        }
        elsif ( $type =~ /char\((\d+)\)/ ) {
            $type = 'Str';
            $size = $1;
        }
        elsif ( $type =~ /int\((\d+)\)/ ) {
            $type = 'Int';
            $size = int( $1 / 2 );
        }
        elsif ( $type =~ /date/ ) {
            next;
        }
        elsif ( $type =~ /^enum\((.+)\)$/ ) {
            next;
        }
        else {
            confess " unhandled column type : $type ";
        }

        $rules{$name} = { type => $type, size => $size };
    }

    $self->_verbose( "leave", $cnt );

    return \%rules;
}

sub _get_enum_data {
    args

        # required
        my $self          => 'Object',
        my $table         => 'Str',
        my $col_data_href => 'HashRef';

    foreach my $col_href ( @{ $self->describe_table($table) } ) {

        my $col_name = $col_href->{FIELD};

        next if $col_href->{EXTRA} =~ /auto/;
        next if exists $col_data_href->{$col_name};

        my $name = $col_href->{FIELD};
        my $type = $col_href->{TYPE};
        my $size;

        if ( $type =~ /^enum\((.+)\)$/ ) {
            my @a = split /,/, $type;
            my $i = int( rand( scalar @a ) );
            $a[$i] =~ /'(\w+)'/;
            my $val = $1;

            $col_data_href->{$col_name} = $val;
        }
    }
}

sub _get_column2alias_lookup {
    args

        # required
        my $self            => 'Object',
        my $table           => 'Str',
        my $constraint_name => 'Str',
        my $alias_href      => 'HashRef',

        # optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    $table = $self->_fq( table => $table, fq => $fq );

    my @cols;
    my %cols2alias;

    my $con_aref = $self->get_constraint(
        table => $table,
        name  => $constraint_name
    );

    foreach my $con_col_href (@$con_aref) {

        my %parm;
        my $col_name = $con_col_href->{COLUMN_NAME};

        if ($self->is_fk_column(
                table  => $table,
                column => $col_name
            )
            )
        {
            my $fk_col_href = $self->_get_fk_column(
                table  => $table,
                column => $col_name
            );

            if ($fq) {
                $parm{schema} = $fk_col_href->{REFERENCED_TABLE_SCHEMA};
            }

            $parm{table} = $fk_col_href->{REFERENCED_TABLE_NAME};
            $col_name
                = $fk_col_href->{REFERENCED_COLUMN_NAME} . " as $col_name";
        }
        else {
            if ($fq) {
                $parm{schema} = $con_col_href->{CONSTRAINT_SCHEMA};
            }

            $parm{table} = $table;
        }
        my $ref_table = $self->_fq( %parm, fq => $fq );

        $cols2alias{$col_name} = $alias_href->{$ref_table};
    }

    return \%cols2alias;
}

sub _get_select_clause {
    args

        # required
        my $self            => 'Object',
        my $table           => 'Str',
        my $constraint_name => 'Str',
        my $alias_href      => 'HashRef',

        # optional
        my $fq => { isa => 'Bool', optional => 1, default => 1 };

    my $col2alias = $self->_get_column2alias_lookup(
        table           => $table,
        constraint_name => $constraint_name,
        alias_href      => $alias_href,
        fq              => $fq
    );

    my @cols;

    foreach my $col ( keys %$col2alias ) {
        push( @cols, sprintf "%s.%s", $col2alias->{$col}, $col );
    }

    return join ', ', @cols;
}

=head1 AUTHOR

John Gravatt, C<< <john at gravatt.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mysql-util-data-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MySQL-Util-Data-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MySQL::Util::Data::Create


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MySQL-Util-Data-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MySQL-Util-Data-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MySQL-Util-Data-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/MySQL-Util-Data-Create/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 John Gravatt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of MySQL::Util::Data::Create

