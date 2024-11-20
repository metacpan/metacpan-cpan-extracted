package Tapper::Schema::TestrunDB::Result::View010TestrunOverviewReports;
our $AUTHORITY = 'cpan:TAPPER';
# the number is to sort classes on deploy
$Tapper::Schema::TestrunDB::Result::View010TestrunOverviewReports::VERSION = '5.0.12';
use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('view_testrun_overview_reports');

# virtual is needed when the query should accept parameters
__PACKAGE__->result_source_instance->is_virtual(0);
__PACKAGE__->result_source_instance->deploy_depends_on( [qw(Tapper::Schema::TestrunDB::Result::ReportgroupTestrun
                                                            Tapper::Schema::TestrunDB::Result::ReportgroupTestrunStats
                                                          )] );
__PACKAGE__->result_source_instance->view_definition
    (
     "select   rgt.testrun_id                  as rgt_testrun_id ".
     "       , max(rgt.report_id)              as primary_report_id ".
     "       , rgts.success_ratio              as rgts_success_ratio ".
     "from reportgrouptestrun      rgt, ".
     "     reportgrouptestrunstats rgts ".
     "where rgt.testrun_id=rgts.testrun_id ".
     "group by rgt.testrun_id, rgts.success_ratio"
    );

__PACKAGE__->add_columns
    (
     'rgt_testrun_id'     => { data_type => 'INT',                },
     'rgts_success_ratio' => { data_type => 'varchar', size => 20 },
     'primary_report_id'  => { data_type => 'INT'                 },
    );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::View010TestrunOverviewReports

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
