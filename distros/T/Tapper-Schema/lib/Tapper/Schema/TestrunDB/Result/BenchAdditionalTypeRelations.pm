package Tapper::Schema::TestrunDB::Result::BenchAdditionalTypeRelations;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::BenchAdditionalTypeRelations::VERSION = '5.0.9';
# ABSTRACT: Tapper - additional values for benchmark data point

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('bench_additional_type_relations');
__PACKAGE__->add_columns(
    'bench_id', {
        data_type           => 'INT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 12,
        is_foreign_key      => 1,
        extra               => {
            unsigned => 1,
        },
    },
    'bench_additional_type_id', {
        data_type           => 'SMALLINT',
        default_value       => undef,
        is_nullable         => 0,
        size                => 6,
        is_foreign_key      => 1,
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

__PACKAGE__->set_primary_key('bench_id','bench_additional_type_id');
__PACKAGE__->belongs_to(
    bench => "${basepkg}::Benchs", { 'foreign.bench_id' => 'self.bench_id'  },
);
__PACKAGE__->belongs_to(
    bench_additional_type => "${basepkg}::BenchAdditionalTypes", { 'foreign.bench_additional_type_id' => 'self.bench_additional_type_id'  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::BenchAdditionalTypeRelations - Tapper - additional values for benchmark data point

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
