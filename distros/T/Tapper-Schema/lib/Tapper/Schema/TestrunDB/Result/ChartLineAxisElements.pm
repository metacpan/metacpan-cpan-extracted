package Tapper::Schema::TestrunDB::Result::ChartLineAxisElements;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartLineAxisElements::VERSION = '5.0.11';
# ABSTRACT: Tapper - Relation Table for Elements for Chart line Axis

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/FilterColumn InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_line_axis_elements');
__PACKAGE__->add_columns(
    'chart_line_axis_element_id', {
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
    'chart_line_axis', {
        data_type           => 'CHAR',
        is_nullable         => 0,
        size                => 1,
        is_enum             => 1,
        extra               => {
            list => [qw(x y)],
        },
    },
    'chart_line_axis_element_number', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        extra               => {
            unsigned => 1,
        },
    },
);

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('chart_line_axis_element_id');
__PACKAGE__->add_unique_constraint(
    'ux_chart_line_axis_elements_01' => ['chart_line_id','chart_line_axis','chart_line_axis_element_number'],
);

__PACKAGE__->belongs_to(
    chart => "${basepkg}::ChartLines",
    { 'foreign.chart_line_id' => 'self.chart_line_id' },
);
__PACKAGE__->might_have(
    axis_separator => "${basepkg}::ChartLineAxisSeparators",
    { 'foreign.chart_line_axis_element_id' => 'self.chart_line_axis_element_id' },
);
__PACKAGE__->might_have(
    axis_column => "${basepkg}::ChartLineAxisColumns",
    { 'foreign.chart_line_axis_element_id' => 'self.chart_line_axis_element_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartLineAxisElements - Tapper - Relation Table for Elements for Chart line Axis

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
