#! perl -I. -w
use t::Test::abeltje;

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

    is(
        $report->arch_os_version_label,
        "arm64 - darwin - 21.6.0 (Mac OS X - macOS 12.5.1 (21G83)) - idefix",
        "->arch_os_version_label"
    );
    is_deeply(
        $report->arch_os_version_pair,
        {
            'label' => 'arm64 - darwin - 21.6.0 (Mac OS X - macOS 12.5.1 (21G83)) - idefix',
            'value' => 'arm64##darwin##21.6.0 (Mac OS X - macOS 12.5.1 (21G83))##idefix'
        },
        "->arch_os_version_pair"
    ) or diag(explain($report->arch_os_version_pair));

    is(
        $report->title,
        "Smoke v5.37.2-448-g03840a1d3f PASS darwin 21.6.0 (Mac OS X - macOS 12.5.1".
        " (21G83)) MacBook Pro (0)  [10 (8 performance and 2 efficiency) cores]",
        "->title"
    );
    is(
        $report->list_title,
        "v5.37.2-448-g03840a1d3f darwin 21.6.0 (Mac OS X - macOS 12.5.1 (21G83))".
        " MacBook Pro (0)  [10 (8 performance and 2 efficiency) cores]",
        "->list_title"
    );

    is($report->duration_in_hhmm, '2 hours 8 minutes', "->duration_in_hhmm");
    is($report->average_in_hhmm, '1 hour 4 minutes', "->average_in_hhmm");
    $schema->storage->disconnect;
    $t->drop_dbic_ok();
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
