package Tapper::Schema::TestrunDB::Result::BenchBackupAdditionalRelations;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::BenchBackupAdditionalRelations::VERSION = '5.0.9';
# ABSTRACT: Tapper - backup for additional value to benchmark relations

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('bench_backkup_additional_relations');
__PACKAGE__->add_columns(
    'bench_backup_value_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 12,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'bench_additional_value_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 12,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
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

__PACKAGE__->set_primary_key('bench_backup_value_id','bench_additional_value_id');
__PACKAGE__->belongs_to(
    bench_value => "${basepkg}::BenchBackupValues", { 'foreign.bench_backup_value_id' => 'self.bench_backup_value_id'  },
);
__PACKAGE__->belongs_to(
    bench_additional_value => "${basepkg}::BenchAdditionalValues", { 'foreign.bench_additional_value_id' => 'self.bench_additional_value_id'  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::BenchBackupAdditionalRelations - Tapper - backup for additional value to benchmark relations

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
