package Tapper::RawSQL::ReportsDB::reports;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::RawSQL::ReportsDB::reports::VERSION = '5.0.12';
use strict;
use warnings;

sub web_list {

    my ( $hr_vals ) = @_;

    my %h_where;
    if ( $hr_vals->{suite_id} && @{$hr_vals->{suite_id}} ) {
        $h_where{suite_id} = 'suite_id IN (' . (join q#,#, @{$hr_vals->{suite_id}}) . ')';
    }
    if ( $hr_vals->{machine_name} && @{$hr_vals->{machine_name}} ) {
        $h_where{machine_name} = q#machine_name IN ('# . (join q#','#, @{$hr_vals->{machine_name}}) . q#')#;
    }
    if ( $hr_vals->{successgrade} ) {
        $h_where{successgrade} = 'successgrade = $successgrade$';
    }
    if ( $hr_vals->{success_ratio} ) {
        $h_where{success_ratio} = 'success_ratio = $success_ratio$';
    }
    if ( $hr_vals->{owner} ) {
        $h_where{owner}      = '`owner` = $owner$';
        $h_where{owner_null} = '1 = 0';
    }
    if ( $hr_vals->{date} ) {
        require DateTime::Format::Strptime;
        my $or_strp = DateTime::Format::Strptime->new( pattern => '%Y/%m/%d', );
        my $or_dt   = $or_strp->parse_datetime( $hr_vals->{date} );
        $hr_vals->{date_from} = $or_dt->strftime( '%F' ) . ' 00:00:00';
        $hr_vals->{date_to}   = $or_dt->strftime( '%F' ) . ' 23:59:59';
        $h_where{date}        = 'created_at BETWEEN $date_from$ AND $date_to$';
    }
    else {
        require DateTime;
        require DateTime::Duration;
        $hr_vals->{cdays} = DateTime->now->subtract(
            DateTime::Duration->new( days => $hr_vals->{days} )
        )->strftime('%F %T');
        $h_where{days}    = 'created_at >= $cdays$'
    }

    my $s_where = join "\nAND ", grep { $_ } @h_where{qw/ suite_id machine_name successgrade success_ratio owner days date /};

    return {
        Pg => "
             (
                 -- reportgrouptestrun
                 SELECT
                     r.id                            AS report_id,
                     CONCAT(
                         'testrun ',
                         rgt.testrun_id
                     )                               AS grouping_id,
                     TO_CHAR(
                         r.created_at,
                         'YYYY-Mon-dd'
                     )                           AS report_date,
                     TO_CHAR(
                         r.created_at,
                         'HH24:MM'
                     )                           AS report_time,
                     s.name                        AS suite_name,
                     r.machine_name,
                     r.peeraddr,
                     r.successgrade,
                     FLOOR( CAST( r.success_ratio AS float ) )        AS success_ratio,
                     rgt.owner                     AS report_owner,
                     (
                         SELECT
                             ri.created_at
                         FROM
                             report ri
                             JOIN reportgrouptestrun rgti
                                 ON ( rgti.report_id = ri.id )
                         WHERE
                             rgti.testrun_id = rgt.testrun_id
                             AND $s_where
                         ORDER BY
                             rgti.primaryreport DESC,
                             rgti.report_id DESC
                         LIMIT
                             1
                     )                               AS primary_date,
                     NULLIF( rgt.primaryreport, 0 )  AS primaryreport
                 FROM
                     report r
                     JOIN suite s
                         ON ( s.id = r.suite_id )
                     JOIN reportgrouptestrun rgt
                         ON ( r.id = rgt.report_id )
                 WHERE
                     $s_where
             )
             UNION
             (
                 -- reportgrouparbitrary
                 SELECT
                     r.id                        AS report_id,
                     CONCAT(
                         'arbitrary ',
                         rgt.arbitrary_id
                     )                           AS grouping_id,
                     TO_CHAR(
                         r.created_at,
                         'YYYY-Mon-dd'
                     )                           AS report_date,
                     TO_CHAR(
                         r.created_at,
                         'HH24:MM'
                     )                           AS report_time,
                     s.name                    AS suite_name,
                     r.machine_name,
                     r.peeraddr,
                     r.successgrade,
                     FLOOR( CAST( r.success_ratio AS float ) )        AS success_ratio,
                     rgt.owner                 AS report_owner,
                     (
                         SELECT
                             ri.created_at
                         FROM
                             report ri
                             JOIN reportgrouparbitrary rgti
                                 ON ( rgti.report_id = ri.id )
                         WHERE
                             rgti.arbitrary_id = rgt.arbitrary_id
                             AND $s_where
                         ORDER BY
                             rgti.primaryreport DESC,
                             rgti.report_id DESC
                         LIMIT
                             1
                     ) AS primary_date,
                     NULLIF( rgt.primaryreport, 0 ) AS primaryreport
                 FROM
                     report r
                     JOIN suite s
                         ON ( s.id = r.suite_id )
                     JOIN reportgrouparbitrary rgt
                         ON ( r.id = rgt.report_id )
                 WHERE
                     $s_where
             )
             UNION
             (
                 -- non related reports
                 SELECT
                     r.id                        AS report_id,
                     ''                          AS grouping_id,
                     TO_CHAR(
                         r.created_at,
                         'YYYY-Mon-dd'
                     )                           AS report_date,
                     TO_CHAR(
                         r.created_at,
                         'HH24:MM'
                     )                           AS report_time,
                     s.name                    AS suite_name,
                     r.machine_name,
                     r.peeraddr,
                     r.successgrade,
                     FLOOR( CAST( r.success_ratio AS float ) )        AS success_ratio,
                     ''                          AS report_owner,
                     r.created_at                AS primary_date,
                     1                           AS primaryreport
                 FROM
                     report r
                     JOIN suite s
                         ON ( s.id = r.suite_id )
                     LEFT JOIN reportgrouptestrun rgt
                         ON ( rgt.report_id = r.id )
                     LEFT JOIN reportgrouparbitrary rga
                         ON ( rga.report_id = r.id )
                 WHERE
                         rgt.report_id IS NULL
                     AND rga.report_id IS NULL
                     AND $s_where
             )
             ORDER BY
                 primary_date DESC,
                 grouping_id DESC,
                 primaryreport DESC,
                 report_id DESC
        ",
        SQLite => "
                -- reportgrouptestrun
                SELECT
                    r.id                            AS report_id,
                    'testrun ' || rgt.testrun_id    AS grouping_id,
                    STRFTIME(
                        '%Y-%m-%d',
                        r.created_at
                    )                               AS report_date,
                    STRFTIME(
                        '%H:%M',
                        r.created_at
                    )                               AS report_time,
                    s.`name`                        AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    CAST( r.success_ratio AS INT )  AS success_ratio,
                    rgt.`owner`                     AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            report ri
                            JOIN reportgrouptestrun rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.testrun_id = rgt.testrun_id
                            AND $s_where
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    )                               AS primary_date,
                    IFNULL( rgt.primaryreport, 0 )  AS primaryreport
                FROM
                    report r
                    JOIN suite s
                        ON ( s.id = r.suite_id )
                    JOIN reportgrouptestrun rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where
            UNION
                -- reportgrouptestrun
                SELECT
                    r.id                                AS report_id,
                    'arbitrary ' || rgt.arbitrary_id    AS grouping_id,
                    STRFTIME(
                        '%Y-%m-%d',
                        r.created_at
                    )                               AS report_date,
                    STRFTIME(
                        '%H:%M',
                        r.created_at
                    )                               AS report_time,
                    s.`name`                        AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    CAST( r.success_ratio AS INT )  AS success_ratio,
                    rgt.`owner`                     AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            report ri
                            JOIN reportgrouparbitrary rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.arbitrary_id = rgt.arbitrary_id
                            AND $s_where
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    )                               AS primary_date,
                    IFNULL( rgt.primaryreport, 0 )  AS primaryreport
                FROM
                    report r
                    JOIN suite s
                        ON ( s.id = r.suite_id )
                    JOIN reportgrouparbitrary rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where
            UNION
                -- non related reports
                SELECT
                    r.id                            AS report_id,
                    ''                              AS grouping_id,
                    STRFTIME(
                        '%Y-%m-%d',
                        r.created_at
                    )                               AS report_date,
                    STRFTIME(
                        '%H:%M',
                        r.created_at
                    )                               AS report_time,
                    s.`name`                        AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    CAST( r.success_ratio AS INT )  AS success_ratio,
                    ''                              AS report_owner,
                    r.created_at                    AS primary_date,
                    1                               AS primaryreport
                FROM
                    report r
                    JOIN suite s
                        ON ( s.id = r.suite_id )
                    LEFT JOIN reportgrouptestrun rgt
                        ON ( rgt.report_id = r.id )
                    LEFT JOIN reportgrouparbitrary rga
                        ON ( rga.report_id = r.id )
                WHERE
                        rgt.report_id IS NULL
                    AND rga.report_id IS NULL
                    AND " . (join "\nAND ", grep { $_ } @h_where{qw/ suite_id machine_name successgrade success_ratio owner_null days date /}) . "
            ORDER BY
                primary_date DESC,
                grouping_id DESC,
                primaryreport DESC,
                report_id DESC
        ",
        mysql => "
            (
                -- reportgrouptestrun
                SELECT
                    r.id                            AS report_id,
                    CONCAT(
                        'testrun ',
                        rgt.testrun_id
                    )                               AS grouping_id,
                    DATE_FORMAT(
                        r.created_at,
                        '%Y-%m-%d'
                    )                           AS report_date,
                    DATE_FORMAT(
                        r.created_at,
                        '%H:%i'
                    )                           AS report_time,
                    s.`name`                        AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    FLOOR( r.success_ratio )        AS success_ratio,
                    rgt.`owner`                     AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            reportsdb.report ri
                            JOIN reportsdb.reportgrouptestrun rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.testrun_id = rgt.testrun_id
                            AND $s_where
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    )                               AS primary_date,
                    IFNULL( rgt.primaryreport, 0 )  AS primaryreport
                FROM
                    reportsdb.report r
                    JOIN reportsdb.suite s
                        ON ( s.id = r.suite_id )
                    JOIN reportsdb.reportgrouptestrun rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where
            )
            UNION
            (
                -- reportgrouparbitrary
                SELECT
                    r.id                        AS report_id,
                    CONCAT(
                        'arbitrary ',
                        rgt.arbitrary_id
                    )                           AS grouping_id,
                    DATE_FORMAT(
                        r.created_at,
                        '%Y-%m-%d'
                    )                           AS report_date,
                    DATE_FORMAT(
                        r.created_at,
                        '%H:%i'
                    )                           AS report_time,
                    s.`name`                    AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    FLOOR( r.success_ratio )    AS success_ratio,
                    rgt.`owner`                 AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            reportsdb.report ri
                            JOIN reportsdb.reportgrouparbitrary rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.arbitrary_id = rgt.arbitrary_id
                            AND $s_where
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    ) AS primary_date,
                    IFNULL( rgt.primaryreport, 0 ) AS primaryreport
                FROM
                    reportsdb.report r
                    JOIN reportsdb.suite s
                        ON ( s.id = r.suite_id )
                    JOIN reportsdb.reportgrouparbitrary rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where
            )
            UNION
            (
                -- non related reports
                SELECT
                    r.id                        AS report_id,
                    ''                          AS grouping_id,
                    DATE_FORMAT(
                        r.created_at,
                        '%Y-%m-%d'
                    )                           AS report_date,
                    DATE_FORMAT(
                        r.created_at,
                        '%H:%i'
                    )                           AS report_time,
                    s.`name`                    AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    FLOOR( r.success_ratio )    AS success_ratio,
                    ''                          AS report_owner,
                    r.created_at                AS primary_date,
                    1                           AS primaryreport
                FROM
                    reportsdb.report r
                    JOIN reportsdb.suite s
                        ON ( s.id = r.suite_id )
                    LEFT JOIN reportsdb.reportgrouptestrun rgt
                        ON ( rgt.report_id = r.id )
                    LEFT JOIN reportsdb.reportgrouparbitrary rga
                        ON ( rga.report_id = r.id )
                WHERE
                        rgt.report_id IS NULL
                    AND rga.report_id IS NULL
                    AND " . (join "\nAND ", grep { $_ } @h_where{qw/ suite_id machine_name successgrade success_ratio owner_null days date /}) . "
            )
            ORDER BY
                primary_date DESC,
                grouping_id DESC,
                primaryreport DESC,
                report_id DESC
        ",
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::RawSQL::ReportsDB::reports

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
