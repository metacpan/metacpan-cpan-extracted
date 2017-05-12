package Tapper::RawSQL::TestrunDB::reports;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::RawSQL::TestrunDB::reports::VERSION = '5.0.9';
use strict;
use warnings;

sub web_list {

    my ( $hr_vals ) = @_;

    my %h_where;
    my $b_essentials = 0;
    if ( $hr_vals->{report_id} ) {
        $b_essentials = 1;
    }
    if ( $hr_vals->{report_date_from} && $hr_vals->{report_date_to} ) {
        $hr_vals->{report_date_min} = "$hr_vals->{report_date_from} 00:00:00";
        $hr_vals->{report_date_max} = "$hr_vals->{report_date_to} 23:59:59";
        $h_where{report_date} = 'created_at BETWEEN $report_date_min$ AND $report_date_max$';
        $b_essentials = 1;
    }

    if (! $b_essentials ) {
        require Carp;
        Carp::croak('missing parameters for sql statement: reports::web_list');
    }

    my %h_where_columns = (
        report_id       => 'id',
        machine_name    => 'machine_name',
        successgrade    => 'successgrade',
        success_ratio   => 'success_ratio',
        owner           => 'owner',
        owner_null      => 'NULL',
        suite_id        => 'suite_id',
    );

    if ( $hr_vals->{owner} ) {
        $hr_vals->{owner_null} = 'exclude everything';
    }
    for my $s_filter ( keys %h_where_columns ) {
        if ( $hr_vals->{$s_filter} ) {
            if ( ref $hr_vals->{$s_filter} eq 'ARRAY' ) {
                if ( @{$hr_vals->{$s_filter}} ) {
                    if ( @{$hr_vals->{$s_filter}} == 1 ) {
                        $h_where{$s_filter} = "$h_where_columns{$s_filter} = \$$s_filter\$";
                    }
                    else {
                        $h_where{$s_filter} = "$h_where_columns{$s_filter} IN (\$$s_filter\$)";
                    }
                }
            }
            else {
                $h_where{$s_filter} = "$h_where_columns{$s_filter} = \$$s_filter\$";
            }
        }
    }

    my @a_main  = ( 'suite_id', 'machine_name', 'successgrade', 'success_ratio', 'owner', [qw/ r report_date /], [qw/ r report_id /] );
    my @a_inner = ( 'suite_id', 'machine_name', 'successgrade', 'success_ratio', 'owner', [qw/ ri report_date /], [qw/ ri report_id /] );
    my @a_sub   = ( 'suite_id', 'machine_name', 'successgrade', 'success_ratio', 'owner_null', [qw/ r report_date /], [qw/ r report_id /] );

    my $s_where_main  = join "\nAND ", map { ref $_ ? $_->[0] . '.' . $h_where{$_->[1]} : $h_where{$_} } grep { ref $_ ? $h_where{$_->[1]} : $h_where{$_} } @a_main;
    my $s_where_inner = join "\nAND ", map { ref $_ ? $_->[0] . '.' . $h_where{$_->[1]} : $h_where{$_} } grep { ref $_ ? $h_where{$_->[1]} : $h_where{$_} } @a_inner;
    my $s_where_sub   = join "\nAND ", map { ref $_ ? $_->[0] . '.' . $h_where{$_->[1]} : $h_where{$_} } grep { ref $_ ? $h_where{$_->[1]} : $h_where{$_} } @a_sub;

    return {
        Pg => "
             (
                 -- reportgrouptestrun
                 SELECT
                     r.id                                       AS report_id,
                     CONCAT(
                         'testrun ',
                         rgt.testrun_id
                     )                                          AS grouping_id,
                     TO_CHAR( r.created_at, 'YYYY-MM-DD' )      AS report_date,
                     TO_CHAR( r.created_at, 'HH24:MM' )         AS report_time,
                     s.name                                     AS suite_name,
                     r.machine_name,
                     r.peeraddr,
                     r.successgrade,
                     FLOOR( CAST( r.success_ratio AS float ) )  AS success_ratio,
                     rgt.owner                                  AS report_owner,
                     (
                         SELECT
                             ri.created_at
                         FROM
                             report ri
                             JOIN reportgrouptestrun rgti
                                 ON ( rgti.report_id = ri.id )
                         WHERE
                             rgti.testrun_id = rgt.testrun_id
                             AND $s_where_inner
                         ORDER BY
                             rgti.primaryreport DESC,
                             rgti.report_id DESC
                         LIMIT
                             1
                     )                                          AS primary_date,
                     NULLIF( rgt.primaryreport, 0 )             AS primaryreport
                 FROM
                     report r
                     JOIN suite s
                         ON ( s.id = r.suite_id )
                     JOIN reportgrouptestrun rgt
                         ON ( r.id = rgt.report_id )
                 WHERE
                     $s_where_main
             )
             UNION
             (
                 -- reportgrouparbitrary
                 SELECT
                     r.id                                       AS report_id,
                     CONCAT(
                         'arbitrary ',
                         rgt.arbitrary_id
                     )                                          AS grouping_id,
                     TO_CHAR( r.created_at, 'YYYY-MM-DD' )      AS report_date,
                     TO_CHAR( r.created_at, 'HH24:MM' )         AS report_time,
                     s.name                                     AS suite_name,
                     r.machine_name,
                     r.peeraddr,
                     r.successgrade,
                     FLOOR( CAST( r.success_ratio AS float ) )  AS success_ratio,
                     rgt.owner                                  AS report_owner,
                     (
                         SELECT
                             ri.created_at
                         FROM
                             report ri
                             JOIN reportgrouparbitrary rgti
                                 ON ( rgti.report_id = ri.id )
                         WHERE
                             rgti.arbitrary_id = rgt.arbitrary_id
                             AND $s_where_inner
                         ORDER BY
                             rgti.primaryreport DESC,
                             rgti.report_id DESC
                         LIMIT
                             1
                     ) AS primary_date,
                     NULLIF( rgt.primaryreport, 0 )             AS primaryreport
                 FROM
                     report r
                     JOIN suite s
                         ON ( s.id = r.suite_id )
                     JOIN reportgrouparbitrary rgt
                         ON ( r.id = rgt.report_id )
                 WHERE
                     $s_where_main
             )
             UNION
             (
                 -- non related reports
                 SELECT
                     r.id                                           AS report_id,
                     ''                                             AS grouping_id,
                     TO_CHAR( r.created_at, 'YYYY-MM-DD' )          AS report_date,
                     TO_CHAR( r.created_at, 'HH24:MM' )             AS report_time,
                     s.name                                         AS suite_name,
                     r.machine_name,
                     r.peeraddr,
                     r.successgrade,
                     FLOOR( CAST( r.success_ratio AS float ) )      AS success_ratio,
                     ''                                             AS report_owner,
                     r.created_at                                   AS primary_date,
                     1                                              AS primaryreport
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
                     AND $s_where_sub
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
                    r.id                                    AS report_id,
                    'testrun ' || rgt.testrun_id            AS grouping_id,
                    STRFTIME( '%Y-%m-%d', r.created_at )    AS report_date,
                    STRFTIME( '%H:%M', r.created_at )       AS report_time,
                    s.`name`                                AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    CAST( r.success_ratio AS INT )          AS success_ratio,
                    rgt.`owner`                             AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            report ri
                            JOIN reportgrouptestrun rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.testrun_id = rgt.testrun_id
                            AND $s_where_inner
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    )                                       AS primary_date,
                    IFNULL( rgt.primaryreport, 0 )          AS primaryreport
                FROM
                    report r
                    JOIN suite s
                        ON ( s.id = r.suite_id )
                    JOIN reportgrouptestrun rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where_main
            UNION
                -- reportgrouptestrun
                SELECT
                    r.id                                    AS report_id,
                    'arbitrary ' || rgt.arbitrary_id        AS grouping_id,
                    STRFTIME( '%Y-%m-%d', r.created_at )    AS report_date,
                    STRFTIME( '%H:%M', r.created_at )       AS report_time,
                    s.`name`                                AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    CAST( r.success_ratio AS INT )          AS success_ratio,
                    rgt.`owner`                             AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            report ri
                            JOIN reportgrouparbitrary rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.arbitrary_id = rgt.arbitrary_id
                            AND $s_where_inner
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    )                                       AS primary_date,
                    IFNULL( rgt.primaryreport, 0 )          AS primaryreport
                FROM
                    report r
                    JOIN suite s
                        ON ( s.id = r.suite_id )
                    JOIN reportgrouparbitrary rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where_main
            UNION
                -- non related reports
                SELECT
                    r.id                                    AS report_id,
                    ''                                      AS grouping_id,
                    STRFTIME( '%Y-%m-%d', r.created_at )    AS report_date,
                    STRFTIME( '%H:%M', r.created_at )       AS report_time,
                    s.`name`                                AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    CAST( r.success_ratio AS INT )          AS success_ratio,
                    ''                                      AS report_owner,
                    r.created_at                            AS primary_date,
                    1                                       AS primaryreport
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
                    AND $s_where_sub
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
                    r.id                                    AS report_id,
                    CONCAT(
                        'testrun ',
                        rgt.testrun_id
                    )                                       AS grouping_id,
                    DATE_FORMAT( r.created_at, '%Y-%m-%d' ) AS report_date,
                    DATE_FORMAT( r.created_at, '%H:%i' )    AS report_time,
                    s.`name`                                AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    FLOOR( r.success_ratio )                AS success_ratio,
                    rgt.`owner`                             AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            testrundb.report ri
                            JOIN testrundb.reportgrouptestrun rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.testrun_id = rgt.testrun_id
                            AND $s_where_inner
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    )                                       AS primary_date,
                    IFNULL( rgt.primaryreport, 0 )          AS primaryreport
                FROM
                    testrundb.report r
                    JOIN testrundb.suite s
                        ON ( s.id = r.suite_id )
                    JOIN testrundb.reportgrouptestrun rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where_main
            )
            UNION
            (
                -- reportgrouparbitrary
                SELECT
                    r.id                                    AS report_id,
                    CONCAT(
                        'arbitrary ',
                        rgt.arbitrary_id
                    )                                       AS grouping_id,
                    DATE_FORMAT( r.created_at, '%Y-%m-%d' ) AS report_date,
                    DATE_FORMAT( r.created_at, '%H:%i' )    AS report_time,
                    s.`name`                                AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    FLOOR( r.success_ratio )                AS success_ratio,
                    rgt.`owner`                             AS report_owner,
                    (
                        SELECT
                            ri.created_at
                        FROM
                            testrundb.report ri
                            JOIN testrundb.reportgrouparbitrary rgti
                                ON ( rgti.report_id = ri.id )
                        WHERE
                            rgti.arbitrary_id = rgt.arbitrary_id
                            AND $s_where_inner
                        ORDER BY
                            rgti.primaryreport DESC,
                            rgti.report_id DESC
                        LIMIT
                            1
                    )                                       AS primary_date,
                    IFNULL( rgt.primaryreport, 0 )          AS primaryreport
                FROM
                    testrundb.report r
                    JOIN testrundb.suite s
                        ON ( s.id = r.suite_id )
                    JOIN testrundb.reportgrouparbitrary rgt
                        ON ( r.id = rgt.report_id )
                WHERE
                    $s_where_main
            )
            UNION
            (
                -- non related reports
                SELECT
                    r.id                                    AS report_id,
                    ''                                      AS grouping_id,
                    DATE_FORMAT( r.created_at, '%Y-%m-%d' ) AS report_date,
                    DATE_FORMAT( r.created_at, '%H:%i' )    AS report_time,
                    s.`name`                                AS suite_name,
                    r.machine_name,
                    r.peeraddr,
                    r.successgrade,
                    FLOOR( r.success_ratio )                AS success_ratio,
                    ''                                      AS report_owner,
                    r.created_at                            AS primary_date,
                    1                                       AS primaryreport
                FROM
                    testrundb.report r
                    JOIN testrundb.suite s
                        ON ( s.id = r.suite_id )
                    LEFT JOIN testrundb.reportgrouptestrun rgt
                        ON ( rgt.report_id = r.id )
                    LEFT JOIN testrundb.reportgrouparbitrary rga
                        ON ( rga.report_id = r.id )
                WHERE
                        rgt.report_id IS NULL
                    AND rga.report_id IS NULL
                    AND $s_where_sub
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

Tapper::RawSQL::TestrunDB::reports

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
