package Tapper::RawSQL::TestrunDB::testruns;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::RawSQL::TestrunDB::testruns::VERSION = '5.0.9';
use strict;
use warnings;

sub web_list {

    my ( $hr_vals ) = @_;

    my @a_where;
    my $b_essentials = 0;
    if ( $hr_vals->{testrun_id} ) {
        $b_essentials = 1;
    }
    if ( $hr_vals->{testrun_date_from} && $hr_vals->{testrun_date_to} ) {
        $hr_vals->{testrun_date_min} = "$hr_vals->{testrun_date_from} 00:00:00";
        $hr_vals->{testrun_date_max} = "$hr_vals->{testrun_date_to} 23:59:59";
        push @a_where, 't.updated_at BETWEEN $testrun_date_min$ AND $testrun_date_max$';
        $b_essentials = 1;
    }

    if (! $b_essentials ) {
        require Carp;
        Carp::croak('missing parameters for sql statement: testruns::web_list');
    }

    my %h_where_columns = (
        testrun_id   => 't.id',
        host         => 'ts.host_id',
        state        => 'ts.status',
        owner        => 't.owner_id',
        topic        => 't.topic_name',
        success      => 'r.successgrade',
    );

    for my $s_filter ( keys %h_where_columns ) {
        if ( $hr_vals->{$s_filter} ) {
            if ( ref $hr_vals->{$s_filter} eq 'ARRAY' ) {
                if ( @{$hr_vals->{$s_filter}} ) {
                    if ( @{$hr_vals->{$s_filter}} == 1 ) {
                        push @a_where, "$h_where_columns{$s_filter} = \$$s_filter\$";
                    }
                    else {
                        push @a_where, "$h_where_columns{$s_filter} IN (\$$s_filter\$)";
                    }
                }
            }
            else {
                push @a_where, "$h_where_columns{$s_filter} = \$$s_filter\$";
            }
        }
    }

    return {
        Pg => q#
            SELECT
                t.id                                                        AS testrun_id,
                FLOOR( CAST( NULLIF( rgts.success_ratio, 0 ) AS float ) )   AS success_ratio,
                r.successgrade,
                r.id                                                        AS primary_report_id,
                t.topic_name,
                TO_CHAR( r.updated_at, 'YYYY-MM-DD' )                       AS testrun_date,
                TO_CHAR( r.updated_at, 'HH24:MM' )                          AS testrun_time,
                NULLIF( r.updated_at, t.updated_at )                        AS updated_at,
                NULLIF( o.login, 'unknown user' )                           AS testrun_owner,
                t.starttime_testrun,
                NULLIF( ts.status, 'unknown status' )                       AS testrun_state,
                IF(
                    ts.id IS NULL,
                    'unknownmachine',
                    IF(
                        h.id IS NULL,
                        IF(
                            ts.status = 'finished',
                            'Host deleted',
                            'No host assigned'
                        ),
                        h.name
                    )
                )                                                           AS machine_name
            FROM
                testrun t
                LEFT JOIN owner o
                    ON ( o.id = t.owner_id )
                LEFT JOIN (
                    reportgrouptestrunstats rgts
                    JOIN reportgrouptestrun rgt
                        ON ( rgt.testrun_id = rgts.testrun_id )
                    JOIN report r
                        ON ( r.id = rgt.report_id )
                    LEFT JOIN suite s
                        ON ( r.suite_id = s.id )
                )
                    ON (
                        rgts.testrun_id = t.id
                        AND rgt.report_id = (
                            SELECT
                                rgti.report_id
                            FROM
                                reportgrouptestrun rgti
                            WHERE
                                rgti.testrun_id = rgt.testrun_id
                            ORDER BY
                                rgti.primaryreport DESC,
                                rgti.report_id ASC
                            LIMIT
                                1
                        )
                    )
                LEFT JOIN (
                    testrun_scheduling ts
                    LEFT JOIN host h
                        ON ( h.id = ts.host_id )
                )
                    ON ( ts.testrun_id = t.id )
            WHERE
                # . ( join "\nAND ", @a_where ) . q#
            ORDER BY
                t.id DESC
        #,
        SQLite => q#
            SELECT
                t.id                                            AS testrun_id,
                CAST( IFNULL( rgts.success_ratio, 0 ) AS INT )  AS success_ratio,
                r.successgrade,
                r.id                                            AS primary_report_id,
                t.topic_name,
                STRFTIME( '%Y-%m-%d', r.updated_at )            AS testrun_date,
                STRFTIME( '%H:%M', r.updated_at )               AS testrun_time,
                IFNULL( r.updated_at, t.updated_at )            AS updated_at,
                IFNULL( o.login, 'unknown user' )               AS testrun_owner,
                t.starttime_testrun,
                IFNULL( ts.status, 'unknown status' )           AS testrun_state,
                CASE WHEN
                    ts.id IS NULL
                THEN
                    'unknownmachine'
                ELSE
                    CASE WHEN
                        h.id IS NULL
                    THEN
                        CASE WHEN
                            ts.status = 'finished'
                        THEN
                            'Host deleted'
                        ELSE
                            'No host assigned'
                        END
                    ELSE
                        h.name
                    END
                END                                             AS machine_name
            FROM
                testrun t
                LEFT JOIN owner o
                    ON ( o.id = t.owner_id )
                LEFT JOIN (
                    reportgrouptestrunstats rgts
                    JOIN reportgrouptestrun rgt
                        ON ( rgt.testrun_id = rgts.testrun_id )
                    JOIN report r
                        ON ( r.id = rgt.report_id )
                    LEFT JOIN suite s
                        ON ( r.suite_id = s.id )
                )
                    ON (
                        rgts.testrun_id = t.id
                        AND rgt.report_id = (
                            SELECT
                                rgti.report_id
                            FROM
                                reportgrouptestrun rgti
                            WHERE
                                rgti.testrun_id = rgt.testrun_id
                            ORDER BY
                                rgti.primaryreport DESC,
                                rgti.report_id ASC
                            LIMIT
                                1
                        )
                    )
                LEFT JOIN (
                    testrun_scheduling ts
                    LEFT JOIN host h
                        ON ( h.id = ts.host_id )
                )
                    ON ( ts.testrun_id = t.id )
            WHERE
                # . ( join "\nAND ", @a_where ) . q#
            ORDER BY
                t.id DESC
        #,
        mysql => q#
            SELECT
                t.id                                        AS testrun_id,
                FLOOR( IFNULL( rgts.success_ratio, 0 ) )    AS success_ratio,
                r.successgrade,
                r.id                                        AS primary_report_id,
                t.topic_name,
                DATE_FORMAT( t.updated_at, '%Y-%m-%d' )     AS testrun_date,
                DATE_FORMAT( t.updated_at, '%H:%i' )        AS testrun_time,
                IFNULL( r.updated_at, t.updated_at )        AS updated_at,
                IFNULL( o.login, 'unknown user' )           AS testrun_owner,
                t.starttime_testrun,
                IFNULL( ts.status, 'unknown status' )       AS testrun_state,
                IF(
                    ts.id IS NULL,
                    'unknownmachine',
                    IF(
                        h.id IS NULL,
                        IF(
                            ts.status = 'finished',
                            'Host deleted',
                            'No host assigned'
                        ),
                        h.name
                    )
                )                                           AS machine_name
            FROM
                testrundb.testrun t
                LEFT JOIN testrundb.owner o
                    ON ( o.id = t.owner_id )
                LEFT JOIN (
                    testrundb.reportgrouptestrunstats rgts
                    JOIN testrundb.reportgrouptestrun rgt
                        ON ( rgt.testrun_id = rgts.testrun_id )
                    JOIN testrundb.report r
                        ON ( r.id = rgt.report_id )
                    LEFT JOIN testrundb.suite s
                        ON ( r.suite_id = s.id )
                )
                    ON (
                        rgts.testrun_id = t.id
                        AND rgt.report_id = (
                            SELECT
                                rgti.report_id
                            FROM
                                testrundb.reportgrouptestrun rgti
                            WHERE
                                rgti.testrun_id = rgt.testrun_id
                            ORDER BY
                                rgti.primaryreport DESC,
                                rgti.report_id ASC
                            LIMIT
                                1
                        )
                    )
                LEFT JOIN (
                    testrundb.testrun_scheduling ts
                    LEFT JOIN testrundb.host h
                        ON ( h.id = ts.host_id )
                )
                    ON ( ts.testrun_id = t.id )
            WHERE
                # . ( join "\nAND ", @a_where ) . q#
            ORDER BY
                t.id DESC
        #,
    };
}

sub continuous_list {
    return {
        'Pg' => q#
            SELECT
                t.id                                            AS testrun_id,
                TO_CHAR( r.updated_at, 'YYYY-MM-DD HH24:MM' )   AS testrun_date,
                ts.status,
                t.topic_name,
                q.name                                          AS queue_name,
                STRING_AGG( h.name, ',' )                       AS hosts,
                NULLIF( o.name, o.login )                       AS owner
            FROM
                testrun t
                JOIN testrun_scheduling ts
                    ON ( t.id = ts.testrun_id )
                JOIN owner o
                    ON ( t.owner_id = o.id )
                JOIN testrun_requested_host trh
                    ON ( t.id = trh.testrun_id )
                JOIN host h
                    ON ( trh.host_id = h.id )
                JOIN queue q
                    ON ( ts.queue_id = q.id )
            WHERE
                ts.auto_rerun = 1
                AND ts.status IN ( 'prepare', 'schedule' )
            GROUP BY
                t.id,
                t.updated_at,
                ts.status,
                t.topic_name,
                queue_name,
                owner
            ORDER BY
                t.id DESC
        #,
        'SQLite' => q#
            SELECT
                t.id                                            AS testrun_id,
                STRFTIME( '%Y-%m-%d %H:%M', t.updated_at )      AS testrun_date,
                ts.status,
                t.topic_name,
                q.name                                          AS queue_name,
                GROUP_CONCAT( h.name )                          AS hosts,
                IFNULL( o.name, o.login )                       AS owner
            FROM
                testrun t
                JOIN testrun_scheduling ts
                    ON ( t.id = ts.testrun_id )
                JOIN owner o
                    ON ( t.owner_id = o.id )
                JOIN testrun_requested_host trh
                    ON ( t.id = trh.testrun_id )
                JOIN host h
                    ON ( trh.host_id = h.id )
                JOIN queue q
                    ON ( ts.queue_id = q.id )
            WHERE
                ts.auto_rerun = 1
                AND ts.status IN ( 'prepare', 'schedule' )
            GROUP BY
                t.id,
                t.updated_at,
                ts.status,
                t.topic_name,
                queue_name,
                owner
            ORDER BY
                t.id DESC
        #,
        'mysql' => q#
            SELECT
                t.id                                            AS testrun_id,
                DATE_FORMAT( t.updated_at, '%Y-%m-%d %H:%i' )   AS testrun_date,
                ts.status,
                t.topic_name,
                q.name                                          AS queue_name,
                GROUP_CONCAT( h.name ORDER BY h.name )          AS hosts,
                IFNULL( o.name, o.login )                       AS owner
            FROM
                testrundb.testrun t
                JOIN testrundb.testrun_scheduling ts
                    ON ( t.id = ts.testrun_id )
                JOIN testrundb.owner o
                    ON ( t.owner_id = o.id )
                JOIN testrundb.testrun_requested_host trh
                    ON ( t.id = trh.testrun_id )
                JOIN testrundb.host h
                    ON ( trh.host_id = h.id )
                JOIN queue q
                    ON ( ts.queue_id = q.id )
            WHERE
                ts.auto_rerun = 1
                AND ts.status IN ( 'prepare', 'schedule' )
            GROUP BY
                t.id,
                t.updated_at,
                ts.status,
                t.topic_name,
                queue_name,
                owner
            ORDER BY
                t.id DESC
        #,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::RawSQL::TestrunDB::testruns

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
