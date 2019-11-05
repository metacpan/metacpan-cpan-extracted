package Tapper::Schema::TestrunDB::Result::ChartVersions;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartVersions::VERSION = '5.0.11';
# ABSTRACT: Tapper - Keep Charts for Tapper-Reports-Web-GUI

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_versions');
__PACKAGE__->add_columns(
    'chart_version_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 11,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 11,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_type_id', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_axis_type_x_id', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_axis_type_y_id', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_version', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_name', {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 64,
    },
    'order_by_x_axis', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        extra               => {
            unsigned => 1,
        },
    },
    'order_by_y_axis', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
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
    'updated_at', {
        data_type           => 'TIMESTAMP',
        default_value       => undef,
        is_nullable         => 1,
    },
);

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('chart_version_id');
__PACKAGE__->add_unique_constraint(
    ux_chart_versions_01 => [ 'chart_id', 'chart_version' ],
);

__PACKAGE__->belongs_to(
    chart => "${basepkg}::Charts",
    { 'foreign.chart_id'    => 'self.chart_id' },
);
__PACKAGE__->belongs_to(
    chart_type => "${basepkg}::ChartTypes",
    { 'foreign.chart_type_id' => 'self.chart_type_id' },
);
__PACKAGE__->belongs_to(
    chart_axis_type_x  => "${basepkg}::ChartAxisTypes",
    { 'foreign.chart_axis_type_id' => 'self.chart_axis_type_x_id' },
);
__PACKAGE__->belongs_to(
    chart_axis_type_y => "${basepkg}::ChartAxisTypes",
    { 'foreign.chart_axis_type_id' => 'self.chart_axis_type_y_id' },
);
__PACKAGE__->has_many(
    chart_lines => 'Tapper::Schema::TestrunDB::Result::ChartLines',
    { 'foreign.chart_version_id' => 'self.chart_version_id' },
);
__PACKAGE__->has_many(
    chart_markings => 'Tapper::Schema::TestrunDB::Result::ChartMarkings',
    { 'foreign.chart_version_id' => 'self.chart_version_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartVersions - Tapper - Keep Charts for Tapper-Reports-Web-GUI

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
