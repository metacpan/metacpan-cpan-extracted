package Tapper::Schema::TestrunDB::Result::BenchSubsumeTypes;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::BenchSubsumeTypes::VERSION = '5.0.11';
# ABSTRACT: Tapper - types of subsume values

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('bench_subsume_types');
__PACKAGE__->add_columns(
    'bench_subsume_type_id', {
        data_type           => 'SMALLINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 6,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'bench_subsume_type', {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 32,
    },
    'bench_subsume_type_rank', {
        data_type           => 'TINYINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 4,
    },
    'datetime_strftime_pattern', {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 1,
        size                => 32,
    },
    'created_at', {
        data_type           => 'TIMESTAMP',
        default_value       => undef,
        is_nullable         => 0,
        set_on_create       => 1,
    },
);


(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('bench_subsume_type_id');
__PACKAGE__->add_unique_constraint(
    'ux_bench_subsume_types_01' => ['bench_subsume_type'],
);

__PACKAGE__->has_many (
    bench_value => "${basepkg}::BenchValues", { 'foreign.bench_subsume_type_id' => 'self.bench_subsume_type_id' },
);
__PACKAGE__->has_many (
    bench_backup_value => "${basepkg}::BenchBackupValues", { 'foreign.bench_subsume_type_id' => 'self.bench_subsume_type_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::BenchSubsumeTypes - Tapper - types of subsume values

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
