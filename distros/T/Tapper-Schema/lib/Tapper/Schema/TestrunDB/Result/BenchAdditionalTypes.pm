package Tapper::Schema::TestrunDB::Result::BenchAdditionalTypes;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::BenchAdditionalTypes::VERSION = '5.0.9';
# ABSTRACT: Tapper - types of additional values for benchmark data points

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('bench_additional_types');
__PACKAGE__->add_columns(
    'bench_additional_type_id', {
        data_type           => 'SMALLINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 6,
        is_auto_increment   => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'bench_additional_type', {
        data_type           => 'VARCHAR',
        default_value       => undef,
        is_nullable         => 0,
        size                => 767,
    },
    'created_at', {
        data_type           => 'TIMESTAMP',
        default_value       => undef,
        is_nullable         => 0,
        set_on_create       => 1,
    },
);


(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key('bench_additional_type_id');
__PACKAGE__->add_unique_constraint(
    'ux_bench_additional_types_01' => ['bench_additional_type'],
);
__PACKAGE__->has_many (
    bench_additional_value => "${basepkg}::BenchAdditionalValues", { 'foreign.bench_additional_type_id' => 'self.bench_additional_type_id' },
);
__PACKAGE__->has_many (
    bench_additional_type_relation => "${basepkg}::BenchAdditionalTypeRelations", { 'foreign.bench_additional_type_id' => 'self.bench_additional_type_id' },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::BenchAdditionalTypes - Tapper - types of additional values for benchmark data points

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
