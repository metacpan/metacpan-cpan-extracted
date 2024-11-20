package Tapper::Schema::TestrunDB::Result::ChartLineRestrictions;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartLineRestrictions::VERSION = '5.0.12';
# ABSTRACT: Tapper - Keep Chart Line Restrictions for Charts

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/FilterColumn InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_line_restrictions');
__PACKAGE__->add_columns(
    'chart_line_restriction_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 11,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_line_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 11,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_line_restriction_operator'   , {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
    },
    'chart_line_restriction_column'   , {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 512,
    },
    'is_template_restriction', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 3,
        extra               => {
            unsigned => 1,
        },
    },
    'is_numeric_restriction', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 3,
        extra               => {
            unsigned => 1,
        },
    },
    'created_at', {
        data_type           => 'TIMESTAMP',
        default_value       => undef,
        is_nullable         => 0,
        set_on_create       => 1,
    },
);


(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('chart_line_restriction_id');

__PACKAGE__->belongs_to(
    chart_line => "${basepkg}::ChartLines",
    { 'foreign.chart_line_id' => 'self.chart_line_id' },
);
__PACKAGE__->has_many(
    chart_line_restriction_values => "${basepkg}::ChartLineRestrictionValues",
    { 'foreign.chart_line_restriction_id' => 'self.chart_line_restriction_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartLineRestrictions - Tapper - Keep Chart Line Restrictions for Charts

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
