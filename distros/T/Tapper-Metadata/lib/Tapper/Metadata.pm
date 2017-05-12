package Tapper::Metadata;
# git description: v5.0.0-1-g7c8654f

our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Metadata::VERSION = '5.0.1';
use strict;
use warnings;
use Hash::Merge;

my $hr_default_config = {
    debug                   => 0,
    max_redo_count          => 25,
    select_cache            => 1,
    tables                  => {
        additional_type_table            => {
            name    => 'bench_additional_types',
            primary => 'bench_additional_type_id',
        },
        additional_value_table           => {
            name        => 'bench_additional_values',
            primary     => 'bench_additional_value_id',
            foreign_key => {
                additional_type_table => 'bench_additional_type_id',
            },
        },
    },
};

sub new {

    my ( $s_self, $hr_atts ) = @_;

    my $or_self = bless {}, $s_self;

    for my $s_key (qw/ dbh /) {
        if (! $hr_atts->{$s_key} ) {
            require Carp;
            Carp::confess("missing '$s_key' parameter");
            return;
        }
    }

    # get tapper benchmark configuration
    $or_self->{config} = { %{$hr_default_config} };

    if ( $or_self->can('get_default_config') ) {
        $or_self->{config} =
            Hash::Merge
                ->new('LEFT_PRECEDENT')
                ->merge(
                    $or_self->get_default_config(),
                    $or_self->{config},
                )
        ;
    }
    if ( $hr_atts->{config} ) {
        $or_self->{config} =
            Hash::Merge
                ->new('LEFT_PRECEDENT')
                ->merge(
                    $hr_atts->{config},
                    $or_self->{config},
                )
        ;
    }

    require CHI;
    if ( $or_self->{config}{select_cache} ) {
        $or_self->{cache} = CHI->new( driver => 'RawMemory', global => 1 );
    }

    my $s_module = "Tapper::Metadata::Query::$hr_atts->{dbh}{Driver}{Name}";

    my $fn_new_sub;
    eval {
        require Module::Load;
        Module::Load::load( $s_module );
        $fn_new_sub = $s_module->can('new');
    };

    if ( $@ || !$fn_new_sub ) {
        require Carp;
        Carp::confess("database engine '$hr_atts->{dbh}{Driver}{Name}' not supported $@");
        return;
    }
    else {
        require DateTime;
        $or_self->{query} = $s_module->new({
            now    => $hr_atts->{now} || DateTime->now->strftime('%F %T'),
            dbh    => $hr_atts->{dbh},
            cache  => $or_self->{cache},
            debug  => $hr_atts->{debug} || 0,
            config => $or_self->{config},
        });
    }

    return $or_self;

}

sub add_single_metadata {

    my ( $or_self, $hr_data, $hr_options ) = @_;

    my $i_redo_count = 0;
    TRANSACTION: {

        my $b_transaction_started = $or_self->{query}->start_transaction();

        eval {

            if (! $hr_data->{TESTRUN} ) {
                die "Testrun ID not found";
            }

            # check for already existing metadata-set
            my $ar_exists;
            eval {
                $ar_exists = $or_self->search_array({
                    select      => [ 'TESTRUN', ],
                    exclusive   => 1,
                    where       => [
                        map {
                            {
                                operator => '=',
                                column   => $_,
                                values   => $hr_data->{$_},
                            },
                        } keys %{$hr_data}
                    ],
                });
            };

            if ( !$ar_exists || @{$ar_exists} < 1 ) {

                # add metadata header
                my $i_header_id = $or_self->{query}->insert_metadata_header(
                    delete $hr_data->{TESTRUN}
                );
                if (! $i_header_id ) {
                    die "cannot insert metadata header";
                }

                # WARNING: Don't add all three entries inside the same loop. This
                #          leads to deadlocks. Add all entries for one table,
                #          after that - go to the next table.

                # add metadata lines
                my %h_deadlock_free_inserts;

                # additional type
                for my $s_add_type ( keys %{$hr_data} ) {

                    my $i_add_type_id = $or_self->{query}->select_addtype_by_name( $s_add_type );
                    if (! $i_add_type_id ) {
                        $i_add_type_id = $or_self->{query}->insert_addtype( $s_add_type );
                    }
                    if (! $i_add_type_id ) {
                        die "cannot find or insert bench additional type id for '$s_add_type'";
                    }

                    $h_deadlock_free_inserts{$i_add_type_id} = $hr_data->{$s_add_type};

                }

                # additional value
                for my $i_add_type ( keys %h_deadlock_free_inserts ) {

                    my $i_add_value_id = $or_self->{query}->select_addvalue_id( $i_add_type, $h_deadlock_free_inserts{$i_add_type} );
                    if (! $i_add_value_id ) {
                        $i_add_value_id = $or_self->{query}->insert_addvalue( $i_add_type, $h_deadlock_free_inserts{$i_add_type}, );
                    }
                    if (! $i_add_value_id ) {
                        die "cannot find or insert bench additional value id for '$i_add_type', '$h_deadlock_free_inserts{$i_add_type}'";
                    }

                    $h_deadlock_free_inserts{$i_add_type} = $i_add_value_id;

                }

                # additional metadata line
                for my $i_add_value_id ( values %h_deadlock_free_inserts ) {
                    $or_self->{query}->insert_metadata_line(
                        $i_header_id, $i_add_value_id,
                    );
                }

            }

        };

        my $b_success = $or_self->{query}->finish_transaction( $b_transaction_started, $@ );

        if (! $b_success ) {
            if ( $@ ) {
                if ( $@ =~ /try restarting transaction/ ) {
                    if ( ++$i_redo_count <= $or_self->{config}{max_redo_count} ) {
                        redo TRANSACTION;
                    }
                }
                print STDERR $@;
                return $@;
            }
            else {
                print STDERR 'unknown error occured';
                return 'unknown error occured';
            }
        }
        else {
            return;
        }

    } # TRANSACTION

}

sub add_multi_metadata {

    my ( $or_self, $ar_data, $hr_options ) = @_;

    my ( $i_counter, @a_error ) = ( 0 );
    for my $hr_data ( @{$ar_data} ) {
        if ( my $s_error = $or_self->add_single_metadata( $hr_data, $hr_options ) ) {
            push @a_error, {
                'index' => $i_counter,
                'error' => $s_error,
            };
        }
        $i_counter++;
    }

    return ( wantarray ? @a_error : ( @a_error ? 0 : 1 ));

}

sub search {

    my ( $or_self, $hr_search ) = @_;

    return $or_self->{query}->select_benchmark_values(
        $hr_search
    );

}

sub search_array {

    my ( $or_self, $hr_search ) = @_;

    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json($hr_search);
        if ( my $ar_search_data = $or_self->{cache}->get("search_array||$s_key") ) {
            return $ar_search_data;
        }
    }

    my ( $or_prepared, undef ) = $or_self->search( $hr_search );
    my $ar_result              = $or_prepared->fetchall_arrayref({});
                                 $or_prepared->finish();

    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "search_array||$s_key" => $ar_result );
    }

    return $ar_result;

}

sub search_hash {

    my ( $or_self, $hr_search ) = @_;

    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json($hr_search);
        if ( my $hr_search_data = $or_self->{cache}->get( "search_hash||$s_key" ) ) {
            return $hr_search_data;
        }
    }

    if (! $hr_search->{keys} ) {
        require Carp;
        Carp::confess(q#cannot get hash search result without 'keys'#);
        return;
    }

    my ( $or_prepared, undef ) = $or_self->search( $hr_search );
    my $hr_result              = $or_prepared->fetchall_hashref($hr_search->{keys});
                                 $or_prepared->finish();

    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "search_hash||$s_key" => $hr_result )
    }

    return $hr_result;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Metadata

=head1 SYNOPSIS

    require YAML::Syck;
    require Tapper::Metadata;
    my $or_meta = Tapper::Metadata->new({
        dbh    => $or_dbh,
        debug  => 0,
        config => YAML::Syck::LoadFile('~/conf/tapper_metadata.conf'),
    });

    my $b_success = $or_meta->add_multi_metadata([
        {
            TESTRUN => 12345,
            key_1   => 'value_1',
            key_2   => 'value_2',
        },{
            TESTRUN => 12346,
            key_3   => 'value_3',
        },
        ...
    ],{
        force => 1,
    });

    my $or_metadata_points = $or_meta->search({
        select      => [
            'TESTRUN',
            'key_2',
        ],
        where       => [
            { operator => '!=', column => 'key_1', values => 'value_1', },
            { operator => '=' , column => 'key_2', values => 'value_2', },
        ],
        order_by    => [
            'key_3',
            { column => 'TESTRUN', direction => 'ASC', numeric => 1 },
        ],
        exclusive   => 1,
        limit       => 2,
        offset      => 1,
    });

    while my $hr_metadata_point ( $or_metadata_points->fetchrow_hashref() ) {
        ...
    }

=head1 DESCRIPTION

B<Tapper::Metadata> is a module for adding metadata values in a standardised
way to the the database. A search function with complexe filters already exists.

=head2 Class Methods

=head3 new

=over 4

=item

Create a new B<Tapper::Metadata> object.

    my $or_meta = Tapper::Metadata->new({
        dbh    => $or_dbh,
        debug  => 0,
        config => YAML::Syck::LoadFile('~/conf/tapper_metadata.conf'),
    });

=over 4

=item dbh

A B<DBI> database handle.

=item config [optional]

Containing the path to the Tapper::Metadata-Configuration-File. See
B<Configuration> for details.

=item debug [optional]

Setting C<debug> to a true value results in multiple debugging informations
written to STDOUT. The default is 0.

=back

=back

=head3 add_single_metadata

=over 4

=item

Add one or more data points to a single metadata to the database.

    my $b_success = $or_meta->add_single_metadata({
        TESTRUN => 12345,
        key_1   => 'value_1',
        key_2   => 'value_2',
    },{
        force => 1
    });

=over 4

=item 1st Parameter HASH

=item 1.1 Parameter Hash => TESTRUN

The Testrun ID to relate metadata with a testrun.

=item 2nd Parameter Hash => force [optional]

Ignore forgivable errors while writing.

=back

=back

=head3 add_multi_metadata

Add one or more data points to a multiple metadata to the database.

    my @a_error_idxs = $or_meta->add_multi_metadata([
        {
            TESTRUN => 12345,
            key_1   => 'value_1',
            key_2   => 'value_2',
        },{
            TESTRUN => 12346,
            key_3   => 'value_3',
        },
        ...
    ],{
        force => 1
    });

=over 4

=item 1st Parameter ARRAY of HASHES

=item 1st 1st Parameter Hash => TESTRUN

The Testrun ID to relate metadata with a testrun.

=item 2nd Parameter Hash => force [optional]

Ignore forgivable errors while writing.

=back

=head3 search

Search for metadata points in the database. Function returns a DBI
Statement Handle.

    my $or_metadata_points = $or_meta->search({
        select      => [
            'TESTRUN',
            'key_2',
        ],
        where       => [
            { operator => '!=', column => 'key_1', values => 'value_1', },
            { operator => '=' , column => 'key_2', values => 'value_2', },
        ],
        where_sql   => q#,
            AND NOT(
                   ${TESTRUN} = 123
                OR ${VALUE}   = '144'
            )
        #,
        order_by    => [
            'key_3',
            { column => 'TESTRUN', direction => 'ASC', numeric => 1 },
        ],
        exclusive   => 1,
        limit       => 2,
        offset      => 1,
    });

=over 4

=item select [optional]

An Array of Strings or Hash References containing additional selected columns.
The default selected columns are:
    TESTRUN

Add additional data "key_2" as column to selection.

    ...
        select      => [
            'TESTRUN',
            'key_2',
        ],
    ...

Get the maximum "TESTRUN" of all selected data points. All other columns
without an aggregation become the C<default_aggregation> from
Tapper::Metadata-Configuration. Possible aggregation types are:

    - min = minimum
    - max = maximum
    - avg = average
    - gem = geometric mean
    - sum = summary
    - cnt = count
    - cnd = distinct value count

    ...
        select      => [
            { column => 'TESTRUN', aggregate => 'max', },
            { column => 'key_2'  ,                     },
        ],
    ...

A aggregation is also possible for the default columns.

    ...
        select      => [
            { column => 'TESTRUN', aggregate => 'max', },
            { column => 'key_2'  , aggregate => 'avg', },
        ],
    ...

All additional values internally stored as strings. For the numeric aggegation
functions "min", "max", "avg", "gem" and "sum" the "numeric" flag must be set to
a true value to cast the value as a numeric.

    ...
        select      => [
            { column => 'TESTRUN', aggregate => 'max', numeric => 1, },
            { column => 'key_2'  , aggregate => 'avg',               },
        ],
    ...

=item where [optional]

An Array of Hash References containing restrictions for metadata points.

    ...
        where       => [
            { operator => '!=', column => 'key_1', values => 'value_1', },
            { operator => '=' , column => 'key_2', values => 'value_2', },
        ],
    ...

- Parameter in Sub-Hash = operator

    =           - equal
    !=          - not equal
    <           - lower
    >           - greater
    <=          - lower equal
    >=          - greater equal
    like        - SQL LIKE
    not like    - SQL NOT LIKE

- Parameter in Sub-Hash = column

A restriction is possible for additional values and the default columns.

- Parameter in Sub-Hash = values

In general there is just a single value. For '=' and '!=' a check for multiple
values is possible. Insert a array reference of values in this case. In SQL it
is implemented with IN and NOT IN.

- Parameter in Sub-Hash = numeric [ optional ]

All additional values internally stored as strings. For the numeric operators
'<', '<=', '>' and '>=' this flag must be set to a true value to cast the value
as a numeric.

=item where_sql [optional]

A String containing an additional where clause. Please use this feature just if
the "where" parameter is not sufficient to restrict.

=item order_by [optional]

An Array of Strings or an Array of Array References determining the order of
returned metadata points.

Array of Strings:
    column to sort with default order direction "ASC" (ascending)

Array of Strings or Hash References
    column    : column to sort
    direction : order direction with possible values "ASC" (ascending) and "DESC" (descending)
    numeric   : set a true value for a numeric sort

    ...
        order_by    => [
            'key_3',
            { column => 'TESTRUN', direction => 'ASC', numeric => 1 },
        ],
    ...

=item limit [optional]

An integer value which determine the number of returned metadata points.

=item offset [optional]

An integer value which determine the number of omitted metadata points.

=back

Select testruns which contains just the metadata "columns" given by the where attribute.

=head3 search_array

Returning all metadata points as Array of Hashes.

    my $ar_metadata_points = $or_meta->search_array({
        select      => [
            'TESTRUN',
            'key_2',
        ],
        where       => [
            { operator => '!=', column => 'key_1', values => 'value_1', },
            { operator => '=' , column => 'key_2', values => 'value_2', },
        ],
        order_by    => [
            'key_3',
            { column => 'TESTRUN', direction => 'ASC', numeric => 1 },
        ],
        limit       => 2,
        offset      => 1,
    });

=head3 search_hash

Returning all metadata points as Hash of Hashes. As compared to search
C<search_array> this function needs the parameter C<keys>. C<keys> is an Array
of Strings which determine the columns used as the keys for the nested hashes.
Every "key" create a new nested hash.

    my $or_metadata_points = $or_meta->search_array({
        keys        => [
            'TESTRUN',
            'key_2',
        ],
        select      => [
            'TESTRUN',
            'key_2',
        ],
        where       => [
            { operator => '!=', column => 'key_1', values => 'value_1', },
            { operator => '=' , column => 'key_2', values => 'value_2', },
        ],
        order_by    => [
            'key_3',
            { column => 'TESTRUN', direction => 'ASC', numeric => 1 },
        ],
        limit       => 2,
        offset      => 1,
    });

=head1 NAME

Tapper::Metadata - Save and search Metadata points by database

=head1 Configuration

The following elements are required in configuration:

=over 4

=item default_aggregation

Default aggregation used for non aggregated columns if an aggregation on any
other column is found.

=item tables

Containing the names of the tables used bei B<Tapper::Metadata>

    tables => {
        additional_type_table            => 'bench_additional_types',
        additional_value_table           => 'bench_additional_values',
        additional_type_relation_table   => 'bench_additional_type_relations',
    }

=item select_cache [optional]

In case of a true value the module cache some select results

=back

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
