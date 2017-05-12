package Tapper::Metadata::Query::default;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Metadata::Query::default::VERSION = '5.0.1';
use strict;
use warnings;
use base 'Tapper::Metadata::Query';

use List::MoreUtils qw( any );

my %h_used_selects;
my %h_default_columns = (
    'TESTRUN'       => { column => 't.id' },
    'TESTPLAN'      => { column => 't.testplan_id' },
    'HEADER_ID'     => { column => 'h.testrun_metadata_header_id' },
    'STATS_FAILED'  => { column => 'rgts.failed', addon => 'stats_table' },
);
my $fn_numeric_operators = sub {
    return $_[0]->{options} && $_[0]->{options}{numeric}
        ? "$_[0]->{column} $_[0]->{operator} (0 + ?)"
        : "$_[0]->{column} $_[0]->{operator} ?"
    ;
};
my %h_operators = (
    '='         => {
        rank    => 0,
        where   => sub {
            return @{$_[0]->{values}} > 1
                ? "$_[0]->{column} IN (" . (join ',', map {'?'} @{$_[0]->{values}}) . ')'
                : "$_[0]->{column} = ?"
        },
    },
    '!='        => {
        rank    => 1,
        where   => sub {
            return @{$_[0]->{values}} > 1
                ? "$_[0]->{column} NOT IN (" . (join ',', map {'?'} @{$_[0]->{values}}) . ')'
                : "$_[0]->{column} != ?"
        }
    },
    '<='        => {
        rank    => 2,
        numeric => 1,
        where   => $fn_numeric_operators,
    },
    '>='        => {
        rank    => 3,
        numeric => 1,
        where   => $fn_numeric_operators,
    },
    '<'         => {
        rank    => 4,
        numeric => 1,
        where   => $fn_numeric_operators,
    },
    '>'         => {
        rank    => 5,
        numeric => 1,
        where   => $fn_numeric_operators,
    },
    'like'      => {
        rank    => 6,
        where   => sub { return "$_[0]->{column} LIKE ?"; },
    },
    'not like'  => {
        rank    => 7,
        where   => sub { return "$_[0]->{column} NOT LIKE ?"; },
    },
);

sub default_columns {
    return \%h_default_columns;
}

sub select_addtype_by_name {

    my ( $or_self, $s_add_type ) = @_;

    if ( $or_self->{cache} ) {
        if ( my $i_addtype_id = $or_self->{cache}->get("addtype||$s_add_type") ) {
            return $i_addtype_id;
        }
    }

    my $hr_additional_type = $or_self->selectrow_hashref(
            "
                SELECT $or_self->{config}{tables}{additional_type_table}{primary}
                FROM $or_self->{config}{tables}{additional_type_table}{name}
                WHERE bench_additional_type = ?
            ",
            [ $s_add_type ],
        )
    ;
    if ( !$hr_additional_type || !$hr_additional_type->{$or_self->{config}{tables}{additional_type_table}{primary}} ) {
        return;
    }
    if ( $or_self->{cache} ) {
        $or_self->{cache}->set(
            "addtype||$s_add_type" => $hr_additional_type->{$or_self->{config}{tables}{additional_type_table}{primary}},
        );
    }

    return $hr_additional_type->{$or_self->{config}{tables}{additional_type_table}{primary}};

}

sub select_addvalue_id {

    my ( $or_self, $i_bench_additional_type_id, $s_bench_additional_value ) = @_;

    if ( $or_self->{cache} ) {
        if ( my $i_bench_additional_value_id = $or_self->{cache}->get("addvalue||$i_bench_additional_type_id||$s_bench_additional_value") ) {
            return $i_bench_additional_value_id;
        }
    }

    my $s_value_where;
    my @a_values = ($i_bench_additional_type_id);
    if ( defined $s_bench_additional_value ) {
        $s_value_where = 'bench_additional_value = ?';
        push @a_values, $s_bench_additional_value;
    }
    else {
        $s_value_where = 'bench_additional_value IS NULL'
    }

    my $ar_additional_type = $or_self->selectrow_arrayref(
            "
                SELECT $or_self->{config}{tables}{additional_value_table}{primary}
                FROM $or_self->{config}{tables}{additional_value_table}{name}
                WHERE $or_self->{config}{tables}{additional_value_table}{foreign_key}{additional_type_table} = ? AND $s_value_where
            ",
            \@a_values,
        )
    ;
    if ( !$ar_additional_type || !$ar_additional_type->[0] ) {
        return;
    }
    if ( $or_self->{cache} ) {
        $or_self->{cache}->set(
            "addvalue||$i_bench_additional_type_id||$s_bench_additional_value" => $ar_additional_type->[0],
        );
    }

    return $ar_additional_type->[0];

}

sub metadata_operators {
    return \%h_operators;
}

sub create_select_column {

    my ( $or_self, $hr_select ) = @_;

    my $s_aggregation   = $hr_select->{aggregate};
    my $s_return_select = $hr_select->{column_internal};

    AGGR: {
        if (! $s_aggregation ) {
            # aggregate all columns if a single column is aggregated
            if ( $hr_select->{aggregate_all} ) {
                $s_aggregation = $or_self->{config}{default_aggregation};
                redo AGGR;
            }
        }
        if ( $s_aggregation ) {

            if ( $hr_select->{numeric} ) {
                $s_return_select = "(0 + $s_return_select)";
            }

            if ( $s_aggregation eq 'min' ) {
                $s_return_select = "MIN( $s_return_select )";
            }
            elsif ( $s_aggregation eq 'max' ) {
                $s_return_select = "MAX( $s_return_select )";
            }
            elsif ( $s_aggregation eq 'avg' ) {
                $s_return_select = "AVG( $s_return_select )";
            }
            elsif ( $s_aggregation eq 'gem' ) {
                $s_return_select = "EXP( SUM( LOG( $s_return_select ) ) / COUNT( $s_return_select ) )";
            }
            elsif ( $s_aggregation eq 'sum' ) {
                $s_return_select = "SUM( $s_return_select )";
            }
            elsif ( $s_aggregation eq 'cnt' ) {
                $s_return_select = "COUNT( $s_return_select )";
            }
            elsif ( $s_aggregation eq 'cnd' ) {
                $s_return_select = "COUNT( DISTINCT $s_return_select )";
            }
            else {
                require Carp;
                Carp::confess("unknown aggregate function '$s_aggregation'");
                return;
            }

        }
    } # AGGR

    my $s_replace_as = $hr_select->{aggregate}
        ? "$hr_select->{aggregate}_$hr_select->{column}"
        : $hr_select->{column}
    ;

    # remove sub if a column has multiple calls
    if ( $h_used_selects{$or_self}{$s_replace_as} ) {
        return;
    }
    $h_used_selects{$or_self}{$s_replace_as} = 1;

    return "$s_return_select AS '$s_replace_as'";

}

sub create_period_check {

    my ( $s_column, $dt_from, $dt_to ) = @_;

    my @a_vals;
    my $s_where;
    if ( $dt_from ) {
        if ( my ( $s_date, $s_time ) = $dt_from =~ /(\d{4}-\d{2}-\d{2})( \d{2}:\d{2}:\d{2})?/ ) {
            $s_where .= "\nAND $s_column > ?";
            push @a_vals, $s_date . ( $s_time || ' 00:00:00' );
        }
        else {
            require Carp;
            Carp::confess(q#unknown date format for 'date_from'#);
            return;
        }
    }
    if ( $dt_to ) {
        if ( my ( $s_date, $s_time ) = $dt_to =~ /(\d{4}-\d{2}-\d{2})( \d{2}:\d{2}:\d{2})?/ ) {
            $s_where .= "\nAND $s_column < ?";
            push @a_vals, $s_date . ( $s_time || ' 23:59:59' );
        }
        else {
            require Carp;
            Carp::confess(q#unknown date format for 'date_to'#);
            return;
        }
    }

    return {
        vals  => \@a_vals,
        where => $s_where,
    };

}

sub select_benchmark_values {

    my ( $or_self, $hr_search ) = @_;

    # clear selected columns
    $h_used_selects{$or_self} = {};

    # deep copy hash
    require JSON::XS;
    $hr_search = JSON::XS::decode_json(
        JSON::XS::encode_json( $hr_search )
    );

    my (
        $s_limit,
        $s_offset,
        $s_order_by,
        @a_select,
        @a_from,
        @a_from_vals,
        @a_where,
        @a_where_vals,
    ) = (
        q##,
        q##,
        q##,
    );

    # limit clause
    if ( $hr_search->{limit} ) {
        if ( $hr_search->{limit} =~ /^\d+$/ ) {
            $s_limit = "LIMIT $hr_search->{limit}";
        }
        else {
            require Carp;
            Carp::confess("invalid limit value '$hr_search->{limit}'");
            return;
        }
    }

    # offset clause
    if ( $hr_search->{offset} ) {
        if ( $hr_search->{offset} =~ /^\d+$/ ) {
            $s_offset = "OFFSET $hr_search->{offset}";
        }
        else {
            require Carp;
            Carp::confess("invalid offset value '$hr_search->{offset}'");
            return;
        }
    }

    # where clause
    my %h_addon;
    my $i_counter = 0;
    my %h_local_from_cache;
    if ( $hr_search->{where} ) {

        my $hr_operators = metadata_operators();
        for my $hr_where ( @{$hr_search->{where}} ) {
            if (! $hr_where->{column} ) {
                require Carp;
                Carp::confess("column is missing in where clause [$i_counter]");
                return;                
            }
            if ( my $hr_operator = $hr_operators->{$hr_where->{operator}} ) {
                $hr_where->{__operator__} = $hr_operator;
            }
            else {
                require Carp;
                Carp::confess("unknown operator '$hr_where->{operator}'");
                return;
            }
            $i_counter++;
        }

        # run search in exclusive mode
        if ( $hr_search->{exclusive} ) {
              my @a_testrun_vals = map { $_->{column} => 1 } grep { $_->{column} ne 'TESTRUN' } @{$hr_search->{where}};
              my %h_testrun_vals = ( @a_testrun_vals );
              push @a_where_vals, scalar( keys %h_testrun_vals );
              push @a_where     , "
                  ? = (
                      SELECT COUNT(1) FROM $or_self->{config}{tables}{lines_table}{name} bar
                      WHERE bar.$or_self->{config}{tables}{lines_table}{foreign_key}{headers_table} = h.$or_self->{config}{tables}{headers_table}{primary}
                  )
              ";
        }

        $i_counter = 0;
        for my $hr_where (
            sort {
                $a->{__operator__}{rank} <=> $b->{__operator__}{rank}
            } @{$hr_search->{where}}
        ) {

            $hr_where->{values} =
                ref $hr_where->{values} eq 'ARRAY'
                    ? $hr_where->{values}
                    : [ $hr_where->{values} ]
            ;

            if ( my $hr_def_col = $h_default_columns{$hr_where->{column}} ) {
                if ( $hr_def_col->{addon} ) {
                    $h_addon{$hr_def_col->{addon}} = 1; 
                }
                push @a_where_vals, @{$hr_where->{values}};
                push @a_where, $hr_where->{__operator__}{where}->({
                    %{$hr_where}, column => $hr_def_col->{column},
                });
            }
            else {
                my $i_add_type_id = $or_self->select_addtype_by_name($hr_where->{column});
                if ( !$i_add_type_id ) {
                    require Carp;
                    Carp::confess("metadata additional value '$hr_where->{column}' not exists");
                    return;
                }
                my $s_column;
                if (! $hr_where->{__operator__}{rank} ) {

                    my $s_where = $hr_where->{__operator__}{where}->({
                        %{$hr_where}, column => $h_local_from_cache{$hr_where->{column}} = "bav$i_counter.bench_additional_value",
                    });

                    push @a_where      , $s_where;
                    push @a_where_vals , @{$hr_where->{values}};
                    push @a_from_vals, $i_add_type_id;
                    push @a_from, "
                        JOIN (
                            $or_self->{config}{tables}{lines_table}{name} bar$i_counter
                            JOIN $or_self->{config}{tables}{additional_value_table}{name} bav$i_counter
                                ON (
                                        bav$i_counter.$or_self->{config}{tables}{additional_value_table}{primary} = bar$i_counter.$or_self->{config}{tables}{lines_table}{foreign_key}{additional_value_table}
                                    AND bav$i_counter.$or_self->{config}{tables}{additional_value_table}{foreign_key}{additional_type_table} = ?
                                )
                        )
                            ON (
                                bar$i_counter.$or_self->{config}{tables}{lines_table}{foreign_key}{headers_table} = h.$or_self->{config}{tables}{headers_table}{primary}
                            )
                    ";
                    
                }
                else {
                    my $s_where = $hr_where->{__operator__}{where}->({
                        %{$hr_where}, column => 'bav.bench_additional_value',
                    });
                    push @a_where_vals, $i_add_type_id, @{$hr_where->{values}};
                    push @a_where, "
                        EXISTS(
                            SELECT * FROM
                                $or_self->{config}{tables}{lines_table}{name} bar
                                JOIN $or_self->{config}{tables}{additional_value_table}{name} bav
                                    ON (
                                            bav.$or_self->{config}{tables}{additional_value_table}{primary} = bar.$or_self->{config}{tables}{lines_table}{foreign_key}{additional_value_table}
                                        AND bav.$or_self->{config}{tables}{additional_value_table}{foreign_key}{additional_type_table} = ?
                                        AND $s_where
                                    )
                            WHERE bar.$or_self->{config}{tables}{lines_table}{foreign_key}{headers_table} = h.$or_self->{config}{tables}{headers_table}{primary}
                        )
                    ";
                }
                $i_counter++;
            }
        }
    }

    # select clause
    my $b_aggregate_all = 0;
    if ( $hr_search->{select} ) {
        for my $i_inner_counter ( 0..$#{$hr_search->{select}} ) {
            if ( ref $hr_search->{select}[$i_inner_counter] ne 'HASH' ) {
                $hr_search->{select}[$i_inner_counter] = { column => $hr_search->{select}[$i_inner_counter] };
            }
            elsif ( !$b_aggregate_all && $hr_search->{select}[$i_inner_counter]{aggregate} ) {
                $b_aggregate_all = 1;
                for my $s_clause (qw/ order_by limit offset /) {
                    if ( $hr_search->{$s_clause} ) {
                        require Carp;
                        Carp::confess("cannot use '$s_clause' with aggregation");
                    }
                }
            }
        }
    }
    # keys check - add all missing columns from 'keys' to 'select'
    if ( $hr_search->{keys} ) {
        for my $s_hash_key ( @{$hr_search->{'keys'}} ) {
            if ( scalar( grep { $s_hash_key eq $_->{column} } @{$hr_search->{select}} ) <= 0 ) {
                push @{$hr_search->{select}}, { column => $s_hash_key };
            }
        }
    }

    if ( $hr_search->{order_by} ) {
        for my $i_inner_counter ( 0..$#{$hr_search->{order_by}} ) {
            if ( ref $hr_search->{order_by}[$i_inner_counter] ne 'HASH' ) {
                $hr_search->{order_by}[$i_inner_counter] = { column => $hr_search->{order_by}[$i_inner_counter] };
            }
        }
        if ( $hr_search->{order_by} ) {
            for my $hr_hash_key ( @{$hr_search->{order_by}} ) {
                if ( scalar( grep { $hr_hash_key->{column} eq $_->{column} } @{$hr_search->{select}} ) <= 0 ) {
                    push @{$hr_search->{select}}, { column => $hr_hash_key->{column} };
                }
            }
        }
    }

    my @a_select_vals;
    for my $hr_select ( @{$hr_search->{select}} ) {

        my $s_column;
        my $s_statement;

        if ( my $hr_def_col = $h_default_columns{$hr_select->{column}} ) {
            if ( $hr_def_col->{addon} ) {
                $h_addon{$hr_def_col->{addon}} = 1;
            } 
            $s_column = $hr_def_col->{column};
        }
        else {
            if ( $h_local_from_cache{$hr_select->{column}} ) {
                $s_column = $h_local_from_cache{$hr_select->{column}};
            }
            else {
                my $i_add_type_id = $or_self->select_addtype_by_name($hr_select->{column});
                if ( !$i_add_type_id ) {
                    require Carp;
                    Carp::confess("metadata additional value '$hr_select->{column}' not exists");
                    return;
                }
    
                push @a_from_vals, $i_add_type_id;
                push @a_from, "
                    LEFT JOIN (
                        $or_self->{config}{tables}{lines_table}{name} bar$i_counter
                        JOIN $or_self->{config}{tables}{additional_value_table}{name} bav$i_counter
                            ON (
                                    bav$i_counter.$or_self->{config}{tables}{additional_value_table}{foreign_key}{additional_type_table} = ?
                                AND bav$i_counter.$or_self->{config}{tables}{additional_value_table}{primary} = bar$i_counter.$or_self->{config}{tables}{lines_table}{foreign_key}{additional_value_table}
                            )
                    )
                        ON ( bar$i_counter.$or_self->{config}{tables}{lines_table}{foreign_key}{headers_table} = h.$or_self->{config}{tables}{headers_table}{primary} )
                ";
                $s_column = $h_local_from_cache{$hr_select->{column}} = "bav$i_counter.bench_additional_value";
                $i_counter++;
            }
        }

        if (
            my $s_select = $or_self->create_select_column({
                %{$hr_select},
                aggregate_all    => $b_aggregate_all,
                column_internal  => $s_column,
            })
        ) {
            push @a_select, $s_select;
        }

    }

    # order_by clause
    if ( $hr_search->{order_by} ) {

        my @a_order_by;
        my %h_order_by_direction = ( 'ASC' => 1, 'DESC' => 1, );

        for my $hr_order_by ( @{$hr_search->{order_by}} ) {
            my $s_column;
            if ( my $hr_def_col = $h_default_columns{$hr_order_by->{column}} ) {
                if ( $hr_def_col->{addon} ) {
                    $h_addon{$hr_def_col->{addon}} = 1;
                }
                $s_column = $hr_def_col->{column};
            }
            elsif ( $h_local_from_cache{$hr_order_by->{column}} ) {
                $s_column = $h_local_from_cache{$hr_order_by->{column}};
            }
            else {
                require Carp;
                Carp::confess("unknown order by column '$hr_order_by->{column}'");
                return;
            }

            my $s_direction = $hr_order_by->{direction} || 'ASC';
            if (! $h_order_by_direction{$s_direction} ) {
                require Carp;
                Carp::confess("unknown order by direction '$s_direction'");
                return;
            }

            push @a_order_by,
                  ( $hr_order_by->{numeric} ? '0 + ' : q## )
                . $s_column
                . ' '
                . $s_direction
            ;
        }
        $s_order_by = 'ORDER BY ' . (join ', ', @a_order_by)
    }

    # replace placeholders inside of raw sql where clause
    my $s_raw_where = $hr_search->{where_sql};
    if ( $s_raw_where ) {
        $s_raw_where =~ s/
            \$\{(.+?)\}
        /
            $h_local_from_cache{$1}
                ? $h_local_from_cache{$1}
                : die "column '$1' not exists in SELECT clause"
        /gex;
    }

    if ( $h_addon{stats_table} ) {
        push @a_from, "
            JOIN $or_self->{config}{tables}{stats_table}{name} rgts
                ON ( rgts.$or_self->{config}{tables}{stats_table}{primary} = t.$or_self->{config}{tables}{stats_table}{foreign_key}{main_table} )
        ";
    }

    return
        $or_self->execute_query(
            "
                SELECT
                    DISTINCT
                        " . ( join ",\n", map {"$_"} @a_select ) . "
                FROM
                    $or_self->{config}{tables}{main_table}{name} t
                    JOIN $or_self->{config}{tables}{headers_table}{name} h
                        ON ( t.id = h.testrun_id )
                    " . ( join "\n", @a_from ) . "
                WHERE
                    " .
                    ( @a_where      ? join "\nAND ", map { $_ } @a_where  : q## ) .
                    ( $s_raw_where  ? " $s_raw_where"                       : q## ) .
                "
                $s_order_by
                $s_limit
                $s_offset
            ", [
                @a_select_vals,
                @a_from_vals,
                @a_where_vals,
            ],
        )
    ;

}

sub insert_metadata_header {

    my ( $or_self, $i_testrun_id ) = @_;

    $or_self->insert( "
        INSERT INTO $or_self->{config}{tables}{headers_table}{name}
            ( testrun_id, created_at )
        VALUES
            ( ?, ? )
    ", [ $i_testrun_id, $or_self->{now} ]);

    return $or_self->last_insert_id(
        $or_self->{config}{tables}{headers_table}{name},
        $or_self->{config}{tables}{headers_table}{primary},
    );

}

sub insert_metadata_line {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->insert( "
        INSERT INTO $or_self->{config}{tables}{lines_table}{name}
            (
                $or_self->{config}{tables}{headers_table}{primary},
                $or_self->{config}{tables}{additional_value_table}{primary}
            )
        VALUES
            ( ?, ? )
    ", \@a_vals );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Metadata::Query::default

=head1 NAME

Tapper::Metadata::Query::default - Base class for the database work used by Tapper::Metadata

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
