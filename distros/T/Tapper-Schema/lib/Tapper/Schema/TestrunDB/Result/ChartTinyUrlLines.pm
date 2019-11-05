package Tapper::Schema::TestrunDB::Result::ChartTinyUrlLines;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartTinyUrlLines::VERSION = '5.0.11';
# ABSTRACT: Tapper - Keep static Chart Url lines for Tapper-Reports-Web-GUI

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_tiny_url_lines');
__PACKAGE__->add_columns(
    'chart_tiny_url_line_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 12,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_tiny_url_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 12,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_line_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 12,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
);

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key(
    'chart_tiny_url_line_id',
);

__PACKAGE__->belongs_to(
    chart_tiny_url => "${basepkg}::ChartTinyUrls", { 'foreign.chart_tiny_url_id' => 'self.chart_tiny_url_id'  },
);
__PACKAGE__->belongs_to(
    chart_line => "${basepkg}::ChartLines", { 'foreign.chart_line_id' => 'self.chart_line_id'  },
);
__PACKAGE__->has_many (
    chart_tiny_url_relation => "${basepkg}::ChartTinyUrlRelations", { 'foreign.chart_tiny_url_line_id' => 'self.chart_tiny_url_line_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartTinyUrlLines - Tapper - Keep static Chart Url lines for Tapper-Reports-Web-GUI

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
