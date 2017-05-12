package Tapper::Schema::TestrunDB::Result::ChartTags;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::ChartTags::VERSION = '5.0.9';
# ABSTRACT: Tapper - Keep Chart Tags for Tapper-Reports-Web-GUI

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('chart_tags');
__PACKAGE__->add_columns(
    'chart_tag_id', {
        data_type           => 'SMALLINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 6,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'chart_tag', {
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

__PACKAGE__->set_primary_key('chart_tag_id');
__PACKAGE__->add_unique_constraint(
    ux_chart_tags_01 => [ 'chart_tag' ],
);

__PACKAGE__->has_many(
    chart_versions => 'Tapper::Schema::TestrunDB::Result::ChartTagRelations',
    { 'foreign.chart_tag_id' => 'self.chart_tag_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::ChartTags - Tapper - Keep Chart Tags for Tapper-Reports-Web-GUI

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
