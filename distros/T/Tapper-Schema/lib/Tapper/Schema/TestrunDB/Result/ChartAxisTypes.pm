package Tapper::Schema::TestrunDB::Result::ChartAxisTypes;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartAxisTypes::VERSION = '5.0.12';
# ABSTRACT: Tapper - Keep Charts Axis Types for Tapper-Reports-Web-GUI

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_axis_types');
__PACKAGE__->add_columns(
    'chart_axis_type_id', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_axis_type_name'   , {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 64,
    },
    'created_at', {
        data_type           => 'TIMESTAMP',
        default_value       => undef,
        is_nullable         => 0,
        set_on_create       => 1,
    },
);


(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('chart_axis_type_id');
__PACKAGE__->add_unique_constraint(
    'ux_chart_axis_types_01' => ['chart_axis_type_name'],
);

__PACKAGE__->has_many(
    chart_versions_column_x => 'Tapper::Schema::TestrunDB::Result::ChartVersions',
    { 'foreign.chart_axis_type_x_id' => 'self.chart_version_id' },
);
__PACKAGE__->has_many(
    chart_versions_column_y => 'Tapper::Schema::TestrunDB::Result::ChartVersions',
    { 'foreign.chart_axis_type_y_id' => 'self.chart_version_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartAxisTypes - Tapper - Keep Charts Axis Types for Tapper-Reports-Web-GUI

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
