package Tapper::Schema::TestrunDB::Result::PrePrecondition;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::PrePrecondition::VERSION = '5.0.12';
# ABSTRACT: Tapper - Containing nested preconditions

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("pre_precondition");
__PACKAGE__->add_columns
    (
     "parent_precondition_id", { data_type => "INT",      default_value => undef, is_nullable => 0, size => 11, is_foreign_key => 1, },
     "child_precondition_id",  { data_type => "INT",      default_value => undef, is_nullable => 0, size => 11, is_foreign_key => 1, },
     "succession",             { data_type => "INT",      default_value => undef, is_nullable => 0, size => 10,                      },
    );

__PACKAGE__->set_primary_key(qw/parent_precondition_id child_precondition_id/);

__PACKAGE__->belongs_to( parent => 'Tapper::Schema::TestrunDB::Result::Precondition', { 'foreign.id' => 'self.parent_precondition_id' });
__PACKAGE__->belongs_to( child  => 'Tapper::Schema::TestrunDB::Result::Precondition', { 'foreign.id' => 'self.child_precondition_id'  });

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::PrePrecondition - Tapper - Containing nested preconditions

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
