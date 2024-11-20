package Tapper::Schema::TestrunDB::Result::ChartLineAdditionals;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartLineAdditionals::VERSION = '5.0.12';
# ABSTRACT: Tapper - Keep additional columns for chart line popup

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_line_additionals');
__PACKAGE__->add_columns(
    'chart_line_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 11,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_line_additional_column', {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 512,
    },
    'chart_line_additional_url', {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 1,
        size                => 1024,
    },
    'created_at', {
        data_type           => 'TIMESTAMP',
        default_value       => undef,
        is_nullable         => 0,
        set_on_create       => 1,
    },
);


(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('chart_line_id','chart_line_additional_column');
__PACKAGE__->belongs_to(
    chart_line => "${basepkg}::ChartLines", { 'foreign.chart_line_id' => 'self.chart_line_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartLineAdditionals - Tapper - Keep additional columns for chart line popup

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
