package Tapper::Schema::TestrunDB::Result::Benchs;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::Benchs::VERSION = '5.0.9';
# ABSTRACT: Tapper - containg benchmark head data

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('benchs');
__PACKAGE__->add_columns(
    'bench_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 11,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'bench_unit_id', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'bench', {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 767,
    },
    'active', {
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
);

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('bench_id');
__PACKAGE__->add_unique_constraint(
    'ux_benchs_01' => ['bench'],
);

__PACKAGE__->belongs_to(
    bench_unit => "${basepkg}::BenchUnits", { 'foreign.bench_unit_id' => 'self.bench_unit_id'  },
);

__PACKAGE__->has_many (
    bench_value => "${basepkg}::BenchValues", { 'foreign.bench_id' => 'self.bench_id' },
);
__PACKAGE__->has_many (
    bench_additional_type_relation => "${basepkg}::BenchAdditionalTypeRelations", { 'foreign.bench_id' => 'self.bench_id' },
);
__PACKAGE__->has_many (
    bench_backup_value => "${basepkg}::BenchBackupValues", { 'foreign.bench_id' => 'self.bench_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::Benchs - Tapper - containg benchmark head data

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
