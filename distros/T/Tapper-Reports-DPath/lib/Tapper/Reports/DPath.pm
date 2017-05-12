## no critic (RequireUseStrict)
package Tapper::Reports::DPath;
# git description: v5.0.1-2-g176ea62

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - Extended DPath functionality for Tapper reports
$Tapper::Reports::DPath::VERSION = '5.0.2';
use 5.010;
        use Moose;

        use Tapper::Model 'model', 'get_hardware_overview'; #, 'get_systems_id_for_hostname'
        use Text::Balanced 'extract_codeblock';
        use Data::DPath::Path;
        use Data::Dumper;
        use CHI;

        our $puresqlabstract = 0;

        use Sub::Exporter -setup => { exports =>           [ 'reportdata' ],
                                      groups  => { all  => [ 'reportdata' ] },
                                    };

        sub _extract_condition_and_part {
                my ($reports_path) = @_;
                my ($condition, $path) = extract_codeblock($reports_path, '{}');
                $path =~ s/^\s*::\s*//;
                return ($condition, $path);
        }

        # better use alias
        sub rds($) { reports_dpath_search(@_) } ## no critic (ProhibitSubroutinePrototypes)

        # better use alias
        sub reportdata($) { reports_dpath_search(@_) } ## no critic (ProhibitSubroutinePrototypes)

        # allow trivial better readable column names
        # - foo => 23           ... mapped to "me.foo" => 23
        # - "report.foo" => 23  ... mapped to "me.foo" => 23
        # - suite_name => "bar" ... mapped to "suite.name" => "bar"
        # - -and => ...         ... mapped to "-and" => ...            # just to ensure that it doesn't produce: "me.-and" => ...
        sub _fix_condition
        {
                no warnings 'uninitialized';
                my $SQLKEYWORDS = 'like|-in|-and|-or';
                my ($condition) = @_;
                # joined suite
                $condition      =~ s/(['"])?\bsuite_name\b(['"])?\s*=>/"suite.name" =>/;        # ';
                $condition      =~ s/(['"])?\breportgroup_testrun_id\b(['"])?\s*=>/"reportgrouptestrun.testrun_id" =>/;                                             # ';
                $condition      =~ s/(['"])?\breportgroup_arbitrary_id\b(['"])?\s*=>/"reportgrouparbitrary.arbitrary_id" =>/;                                       # ';
                $condition      =~ s/([^-\w])(['"])?((report|me)\.)?(?<!suite\.)(?<!reportgrouparbitrary\.)(?<!reportgrouptestrun\.)(?!$SQLKEYWORDS)(\w+)\b(['"])?(\s*)=>/$1"me.$5" =>/;        # ';

                return $condition;

        }

        # ===== CACHE =====

        # ----- cache complete Tapper::Reports::DPath queries -----

        sub _cachekey_whole_dpath {
                my ($reports_path) = @_;
                my $key = ($ENV{TAPPER_DEVELOPMENT} || "0") . '::' . $reports_path;
                return $key;
        }

        sub cache_whole_dpath  {
                my ($reports_path, $rs_count, $res) = @_;

                return if $ENV{HARNESS_ACTIVE};

                my $cache = CHI->new( driver => 'File',
                                      root_dir => '/tmp/cache/dpath',
                                      serializer => 'Data::Dumper',
                                      compress => 1,
                                    );

                $cache->clear() if -e '/tmp/TAPPER_CACHE_CLEAR';

                # we cache on the dpath
                # but need count to verify and maintain cache validity

#                say STDERR "  -> set whole: $reports_path ($rs_count)";
                $cache->set( _cachekey_whole_dpath($reports_path),
                             {
                              count => $rs_count,
                              res   => $res,
                             });
        }

        sub cached_whole_dpath {
                my ($reports_path, $rs_count) = @_;

                return if $ENV{HARNESS_ACTIVE};

                my $cache = CHI->new( driver => 'File',
                                      root_dir => '/tmp/cache/dpath',
                                      serializer => 'Data::Dumper',
                                      compress => 1,
                                    );
                $cache->clear() if -e '/tmp/TAPPER_CACHE_CLEAR';
                my $cached_res = $cache->get(  _cachekey_whole_dpath($reports_path) );

                my $cached_res_count = $cached_res->{count} || 0;
#                say STDERR "  <- get whole: $reports_path ($rs_count vs. $cached_res_count)";
                return if not defined $cached_res;

                if ($cached_res_count == $rs_count) {
#                        say STDERR "  Gotcha!";
                        return $cached_res->{res}
                }

                # clean up when matching report count changed
                $cache->remove( $reports_path );
                return;
        }

        # ----- cache single report dpaths queries -----

        sub _cachekey_single_dpath {
                my ($path, $reports_id) = @_;
                my $key = ($ENV{TAPPER_DEVELOPMENT} || "0") . '::' . $reports_id."::".$path;
                #say STDERR "  . $key";
                return $key;
        }

        sub cache_single_dpath {
                my ($path, $reports_id, $res) = @_;

                return if $ENV{HARNESS_ACTIVE};

                my $cache = CHI->new( driver => 'File',
                                      root_dir => '/tmp/cache/dpath',
                                      serializer => 'Data::Dumper',
                                      compress => 1,
                                    );
                $cache->clear() if -e '/tmp/TAPPER_CACHE_CLEAR';
                $cache->set( _cachekey_single_dpath( $path, $reports_id ),
                             $res
                           );
        }

        sub cached_single_dpath {
                my ($path, $reports_id) = @_;

                return if $ENV{HARNESS_ACTIVE};

                my $cache = CHI->new( driver => 'File',
                                      root_dir => '/tmp/cache/dpath',
                                      serializer => 'Data::Dumper',
                                      compress => 1,
                                    );
                $cache->clear() if -e '/tmp/TAPPER_CACHE_CLEAR';
                my $cached_res = $cache->get( _cachekey_single_dpath( $path, $reports_id ));

#                print STDERR "  <- get single: $reports_id -- $path: ".Dumper($cached_res);
                return $cached_res;
        }

        # ===== the query search =====

        sub reports_dpath_search($) { ## no critic (ProhibitSubroutinePrototypes)
                my ($reports_path) = @_;

                my ($condition, $path) = _extract_condition_and_part($reports_path);
                my $dpath              = new Data::DPath::Path( path => $path );
                $condition             = _fix_condition($condition) unless $puresqlabstract;
                my %condition          = $condition ? %{ eval $condition } : (); ## no critic (ProhibitStringyEval)
                my $rs = model('TestrunDB')->resultset('Report')->search
                    (
                     {
                      %condition
                     },
                     {
                      order_by  => 'me.id asc',
                      columns   => [ qw(
                                               id
                                               suite_id
                                               suite_version
                                               reportername
                                               peeraddr
                                               peerport
                                               peerhost
                                               successgrade
                                               total
                                               failed
                                               parse_errors
                                               passed
                                               skipped
                                               todo
                                               todo_passed
                                               success_ratio
                                               starttime_test_program
                                               endtime_test_program
                                               machine_name
                                               machine_description
                                               created_at
                                               updated_at
                                      )],
                      join      => [ 'suite',      'reportgrouptestrun',            'reportgrouparbitrary'             ],
                      '+select' => [ 'suite.name', 'reportgrouptestrun.testrun_id', 'reportgrouparbitrary.arbitrary_id'],
                      '+as'     => [ 'suite.name', 'reportgrouptestrun.testrun_id', 'reportgrouparbitrary.arbitrary_id'],
                     }
                    );
                my $rs_count = $rs->count();
                my @res = ();

                # layer 2 cache
                my $cached_res = cached_whole_dpath( $reports_path, $rs_count );
                return @$cached_res if defined $cached_res;

                while (my $row = $rs->next)
                {
                        my $report_id = $row->id;
                        # layer 1 cache

                        my $cached_row_res = cached_single_dpath( $path, $report_id );

                        if (defined $cached_row_res) {
                                push @res, @$cached_row_res;
                                next;
                        }

                        my $data = _as_data($row);
                        my @row_res = $dpath->match( $data );

                        cache_single_dpath($path, $report_id, \@row_res);

                        push @res, @row_res;
                }

                cache_whole_dpath($reports_path, $rs_count, \@res);

                return @res;
        }

        sub _dummy_needed_for_tests {
                # once there were problems with eval
                return eval "12345"; ## no critic (ProhibitStringyEval)
        }

        sub _groupcontext {
                my ($report) = @_;

                my %groupcontext = ();
                my $id = $report->id;
                my $rga = $report->reportgrouparbitrary;
                my $rgt = $report->reportgrouptestrun;
                my %groupreports = (
                                    arbitrary    => $rga ? scalar $rga->groupreports : undef,
                                    arbitrary_id => $rga ?        $rga->arbitrary_id : undef,
                                    testrun      => $rgt ? scalar $rgt->groupreports   : undef,
                                    testrun_id   => $rgt ?        $rgt->testrun_id     : undef,
                                   );

                # if ($report->reportgrouptestrun) {
                #         my $rgt_id = $report->reportgrouptestrun->testrun_id;
                #         my $rgt_reports = model('TestrunDB')->resultset('ReportgroupTestrun')->search({ testrun_id => $rgt_id});
                #         # say STDERR "\nrgt $rgt_id count: ", $rgt_reports->count;
                # }

                foreach my $type (qw(arbitrary testrun))
                {
                        next unless $groupreports{$type};
                        my $group_id = $groupreports{"${type}_id"};

                        # say STDERR "${type}_id: ", $groupreports{"${type}_id"};
                        # say STDERR "  groupreports{$type}.count: ",    $groupreports{$type}->count;
                        # say STDERR "* $id - groupreports{$type}.count: ",    $groupreports{$type}->count;
                        while (my $groupreport = $groupreports{$type}->next)
                        {
                                my $groupreport_id = $groupreport->id;
                                # say STDERR "  gr.id: $groupreport_id";
                                my @greportsection_meta = ();
                                my $grsections = $groupreport->reportsections;
                                # say STDERR "* $groupreport_id GROUPREPORT_SECTIONS count: ", $grsections->count;
                                while (my $section = $grsections->next)
                                {
                                        my %columns = $section->get_columns;
                                        foreach (keys %columns) {
                                                delete $columns{$_} unless defined $columns{$_};
                                        }
                                        delete $columns{$_} foreach qw(succession name id report_id);
                                        push @greportsection_meta, {
                                                                    $section->name => {
                                                                                       %columns
                                                                                      }
                                                                   }
                                            if keys %columns;
                                }
                                my $primary = 0;
                                $primary = 1 if $type eq "arbitrary" && $groupreport->reportgrouparbitrary->primaryreport;
                                $primary = 1 if $type eq "testrun"   && $groupreport->reportgrouptestrun->primaryreport;

                                $groupcontext{$type}{$group_id}{$groupreport_id}{myself}     = $groupreport_id == $id ? 1 : 0;
                                $groupcontext{$type}{$group_id}{$groupreport_id}{primary}    = $primary ? 1 : 0;
                                $groupcontext{$type}{$group_id}{$groupreport_id}{meta}       = \@greportsection_meta;
                        }
                }

                # say STDERR Dumper(\%groupcontext);
                return \%groupcontext;
        }

        sub _reportgroupstats {
                my ($report) = @_;

                my $rgt = $report->reportgrouptestrun;
                my $reportgroupstats = {};

                # create report group stats
                if ($report->reportgrouptestrun and $report->reportgrouptestrun->testrun_id)
                {
                        my $rgt_stats = model('TestrunDB')->resultset('ReportgroupTestrunStats')->find($rgt->testrun_id);
                        unless ($rgt_stats and $rgt_stats->testrun_id)
                        {
                                # This is just a fail-back mechanism, in case the "fix-missinging-groupstats" script has not yet been run.
                                $rgt_stats = model('TestrunDB')->resultset('ReportgroupTestrunStats')->new({ testrun_id => $rgt->testrun_id});
                                $rgt_stats->update_failed_passed;
                                $rgt_stats->insert;
                        }
                        my @stat_fields = (qw/failed passed total parse_errors skipped todo todo_passed success_ratio/);
                        no strict 'refs'; ## no critic (ProhibitNoStrict)
                        $reportgroupstats = {
                                             map { ($_ => $rgt_stats->$_ ) } @stat_fields
                                            };
                }
                return $reportgroupstats;
        }

        sub _as_data
        {
                my ($report) = @_;

                my $hwdb;
                if (my $host  = model('TestrunDB')->resultset("Host")->search({name => $report->machine_name}, {rows => 1})->first) {
                        $hwdb = get_hardware_overview($host->id);
                }
                my %hardwaredb_overview = (defined($hwdb) and %$hwdb) ? (hardwaredb => $hwdb) : ();

                my $reportgroupstats = _reportgroupstats($report);

                my $simple_hash = {
                                   report       => {
                                                    $report->get_columns,
                                                    suite_name               => $report->suite ? $report->suite->name : 'unknown',
                                                    reportgroup_testrun_id   => $report->reportgrouptestrun ? $report->reportgrouptestrun->testrun_id : undef,
                                                    reportgroup_arbitrary_id => $report->reportgrouparbitrary ? $report->reportgrouparbitrary->arbitrary_id : undef,
                                                    machine_name             => $report->machine_name || 'unknown',
                                                    created_at_ymd_hms       => $report->created_at->ymd('-')." ".$report->created_at->hms(':'),
                                                    created_at_ymd           => $report->created_at->ymd('-'),
                                                    %hardwaredb_overview,
                                                    groupstats               => {
                                                                                 DEPRECATED => 'BETTER_USE_groupstats_FROM_ONE_LEVEL_ABOVE',
                                                                                 %$reportgroupstats,
                                                                                 },
                                                   },
                                   results      => $report->get_cached_tapdom,
                                   groupcontext => _groupcontext($report),
                                   groupstats   => $reportgroupstats,
                                  };
                return $simple_hash;
        }
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::DPath - Tapper - Extended DPath functionality for Tapper reports

=head1 SYNOPSIS

    use Tapper::Reports::DPath 'reports_dpath_search';
    # the first bogomips entry of math sections:
    @resultlist = reportdata (
                     '{ suite_name => "TestSuite-LmBench" } :: /tap/section/math/*/bogomips[0]'
                  );
    # all report IDs of suite_id 17 that FAILed:
    @resultlist = reportdata (
                     '{ suite_name => "TestSuite-LmBench" } :: /suite_id[value == 17]/../successgrade[value eq 'FAIL']/../id'
                  );

 #
 # '{ "reportgrouptestrun.testrun_id" => 4711 } :: /suite_id[value == 17]/../successgrade[value eq 'FAIL']/../id
 #
 # '{ "reportgrouparbitrary.arbitrary_id" => "fc123a2" } :: /suite_id[value == 17]/../successgrade[value eq 'FAIL']/../id

This searches all reports of the test suite "TestSuite-LmBench" and
furthermore in them for a TAP section "math" with the particular
subtest "bogomips" and takes the first array entry of them.

The part before the '::' selects reports to search in a DBIx::Class
search query, the second part is a normal L<Data::DPath|Data::DPath>
expression that matches against the datastructure that is build from
the DB.

=head1 API FUNCTIONS

=head2 reports_dpath_search

Takes an extended DPath expression, applies it to Tapper Reports
with TAP::DOM structure and returns the matching results in an array.

=head2 rds

Alias for reports_dpath_search.

=head2 reportdata

Alias for reports_dpath_search.

=head1 UTILITY FUNCTIONS

=head2 cache_single_dpath

Cache a result for a raw dpath on a report id.

=head2 cached_single_dpath

Return cached result for a raw dpath on a report id.

=head2 cache_whole_dpath

Cache a result for a complete tapper::dpath on all reports.

=head2 cached_whole_dpath

Return cached result for a complete tapper::dpath on all reports.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
