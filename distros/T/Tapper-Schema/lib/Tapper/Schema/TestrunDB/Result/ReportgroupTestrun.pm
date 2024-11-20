package Tapper::Schema::TestrunDB::Result::ReportgroupTestrun;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ReportgroupTestrun::VERSION = '5.0.12';
# ABSTRACT: Tapper - Containing relations between testruns and reports

use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("reportgrouptestrun");
__PACKAGE__->add_columns
    (
     "testrun_id",    { data_type => "INT",     default_value => undef,  is_nullable => 0, size => 11, is_foreign_key => 1, },
     "report_id",     { data_type => "INT",     default_value => undef,  is_nullable => 0, size => 11, is_foreign_key => 1, },
     "primaryreport", { data_type => "INT",     default_value => undef,  is_nullable => 1, size => 11,                      },
     "owner",         { data_type => "VARCHAR", default_value => undef,  is_nullable => 1, size => 255,                      },
    );

__PACKAGE__->set_primary_key(qw/testrun_id report_id/);

__PACKAGE__->might_have ( reportgrouptestrunstats => 'Tapper::Schema::TestrunDB::Result::ReportgroupTestrunStats', { 'foreign.testrun_id' => 'self.testrun_id' }, { is_foreign_key_constraint => 0 } );
__PACKAGE__->belongs_to ( report => 'Tapper::Schema::TestrunDB::Result::Report', { 'foreign.id' => 'self.report_id' } );

# -------------------- methods on results --------------------


sub groupreports {
        my ($self) = @_;

        my @report_ids;
        my $rg = $self->result_source->schema->resultset('ReportgroupTestrun')->search({ testrun_id => $self->testrun_id });
        while (my $rg_entry = $rg->next) {
                push @report_ids, $rg_entry->report_id;
        }
        return $self->result_source->schema->resultset('Report')->search({ id => [ -or => [ @report_ids ] ] });
}


sub sqlt_deploy_hook
{
        my ($self, $sqlt_table) = @_;
        $sqlt_table->add_index(name => 'reportgrouptestrun_idx_report_id', fields => ['report_id']);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ReportgroupTestrun - Tapper - Containing relations between testruns and reports

=head2 groupreports

Return group of all reports belonging to this same testrun.

=head2 sqlt_deploy_hook

Add useful indexes at deploy time.

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
