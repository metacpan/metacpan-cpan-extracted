#! perl -I. -w
use t::Test::abeltje;

use Date::Parse qw( str2time );
use DateTime;
use JSON;
use Test::DBIC::SQLite;

{
    my $t = Test::DBIC::SQLite->new(
        schema_class => 'Perl5::CoreSmokeDB::Schema'
    );
    my $schema = $t->connect_dbic_ok();

    my $smoke_data = read_json('t/data/report1.json');


    my $report = create_full_report($schema, $smoke_data);
    isa_ok($report, 'Perl5::CoreSmokeDB::Schema::Result::Report');

    my $flat_report = $report->as_hashref();
    is_deeply(
        $flat_report,
        {
            applied_patches  => '',
            architecture     => 'arm64',
            compiler_msgs    => '',
            config_count     => 2,
            cpu_count        => ' [10 (8 performance and 2 efficiency) cores]',
            cpu_description  => 'MacBook Pro (0)',
            duration         => 7686,
            git_describe     => 'v5.37.2-448-g03840a1d3f',
            git_id           => '03840a1d3fe4ab4c1bb97279794abab6915b351e',
            harness3opts     => '',
            harness_only     => '0',
            hostname         => 'idefix',
            id               => 1,
            lang             => undef,
            lc_all           => undef,
            log_file         => undef,
            manifest_msgs    => 'MANIFEST did not declare \'.mailmap\'',
            nonfatal_msgs    => '',
            osname           => 'darwin',
            osversion        => '21.6.0 (Mac OS X - macOS 12.5.1 (21G83))',
            out_file         => undef,
            perl_id          => '5.37.4',
            plevel           => '5.037002zzz448',
            reporter         => '',
            reporter_version => '0.054',
            sconfig_id       => 0,
            skipped_tests    => '',
            smoke_branch     => 'blead',
            smoke_date       => '2022-09-06T01:05:04Z',
            smoke_perl       => '5.34.0',
            smoke_revision   => '1.77',
            smoke_version    => '1.77',
            smoker_version   => '0.046',
            summary          => 'PASS',
            test_jobs        => undef,
            user_note        => '',
            username         => 'abeltje'
        },
        "Simple serialisation ->as_hashref()"
    ) or diag(explain($flat_report));
}

abeltje_done_testing();

sub read_json {
    my ($filename) = @_;

    if (open(my $fh, '<', $filename)) {
        my $json = do { local $/; <$fh> };
        return from_json($json);
    }
    die "Cannot open($filename): $!";
}

sub get_report_data {
    my ($smoke_data) = @_;

    my $report_data = {
        %{ $smoke_data->{'sysinfo'} },
        sconfig_id => 0,
    };
    $report_data->{lc($_)} = delete $report_data->{$_} for keys %$report_data;
    $report_data->{smoke_date} = DateTime->from_epoch(
        epoch     => str2time($report_data->{smoke_date}),
        time_zone => 'UTC',
    );

    my @to_unarray = qw/
        skipped_tests applied_patches
        compiler_msgs manifest_msgs nonfatal_msgs
    /;
    $report_data->{$_} = join("\n", @{$smoke_data->{$_} || []}) for @to_unarray;

    my @other_data = qw/harness_only harness3opts summary/;
    $report_data->{$_} = $smoke_data->{$_} for @other_data;

    return $report_data;
}

sub create_full_report {
    my ($schema, $smoke_data) = @_;

    my $report_data = get_report_data($smoke_data);

    my $report = $schema->txn_do(
        sub {
            my $r = $schema->resultset('Report')->create($report_data);
            $r->discard_changes;

            for my $config (@{ $smoke_data->{configs}}) {
                my $results = delete($config->{'results'});
                for my $field (qw/cc ccversion/) {
                    $config->{$field} ||= '?';
                }
                $config->{started} = DateTime->from_epoch(
                    epoch     => str2time($config->{started}),
                    time_zone => 'UTC',
                );

                my $conf = $r->create_related('configs', $config);

                for my $result (@$results) {
                    my $failures = delete($result->{'failures'});
                    my $res = $conf->create_related('results', $result);

                    for my $failure (@$failures) {
                        $failure->{'extra'} = join("\n", @{$failure->{'extra'}});
                        my $db_failure = $schema->resultset(
                            'Failure'
                        )->find_or_create(
                            $failure,
                            {key => 'failure_test_status_extra_key'}
                        );
                        $schema->resultset('FailureForEnv')->create(
                            {
                                result_id  => $res->id,
                                failure_id => $db_failure->id,
                            }
                        );
                    }
                }
            }

            return $r;
        }
    );
}
