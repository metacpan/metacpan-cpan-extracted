package Tapper::Schema::TestrunDB::Result::View020TestrunOverview;
our $AUTHORITY = 'cpan:TAPPER';
# the number is to sort classes on deploy
$Tapper::Schema::TestrunDB::Result::View020TestrunOverview::VERSION = '5.0.9';
use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('view_testrun_overview');

# virtual is needed when the query should accept parameters
__PACKAGE__->result_source_instance->is_virtual(0);
__PACKAGE__->result_source_instance->deploy_depends_on( [qw(Tapper::Schema::TestrunDB::Result::View010TestrunOverviewReports
                                                            Tapper::Schema::TestrunDB::Result::Report
                                                            Tapper::Schema::TestrunDB::Result::Suite
                                                          )] );
__PACKAGE__->result_source_instance->view_definition
    (
     "select   vtor.primary_report_id  as vtor_primary_report_id ".
     "       , vtor.rgt_testrun_id     as vtor_rgt_testrun_id ".
     "       , vtor.rgts_success_ratio as vtor_rgts_success_ratio ".
     "       , report.id               as report_id ".
     "       , report.machine_name     as report_machine_name ".
     "       , report.created_at       as report_created_at ".
     "       , report.suite_id         as report_suite_id ".
     "       , suite.name              as report_suite_name ".
     "from view_testrun_overview_reports vtor, ".
     "     report report, ".
     "     suite suite ".
     "where CAST(vtor.primary_report_id as UNSIGNED INTEGER)=report.id and ".
     "      report.suite_id=suite.id"
    );

__PACKAGE__->add_columns
    (
     # view_testrun_overview_reports
     'vtor_primary_report_id'   => { data_type => 'INT',      size => 11  },
     'vtor_rgt_testrun_id'      => { data_type => 'INT',      size => 11  },
     'vtor_rgts_success_ratio'  => { data_type => 'varchar',  size => 20  },
     # report
     'report_id'                => { data_type => 'INT',      size => 11  },
     'report_machine_name'      => { data_type => 'varchar',  size => 50  },
     'report_created_at'        => { data_type => 'DATETIME'              },
     # suite
     'report_suite_id'          => { data_type => 'INT',      size => 11  },
     'report_suite_name'        => { data_type => 'varchar',  size => 255 },
    );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::View020TestrunOverview

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
