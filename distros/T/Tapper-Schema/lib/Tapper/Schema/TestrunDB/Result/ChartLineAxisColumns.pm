package Tapper::Schema::TestrunDB::Result::ChartLineAxisColumns;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartLineAxisColumns::VERSION = '5.0.9';
# ABSTRACT: Tapper - containing column name as element for chart axis

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/FilterColumn InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_line_axis_columns');
__PACKAGE__->add_columns(
    'chart_line_axis_element_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 11,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_line_axis_column', {
        data_type           => 'VARCHAR',
        is_nullable         => 0,
        size                => 512,
    },
);

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('chart_line_axis_element_id');
__PACKAGE__->belongs_to(
    chart => "${basepkg}::ChartLineAxisElements",
    { 'foreign.chart_line_axis_element_id' => 'self.chart_line_axis_element_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartLineAxisColumns - Tapper - containing column name as element for chart axis

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
