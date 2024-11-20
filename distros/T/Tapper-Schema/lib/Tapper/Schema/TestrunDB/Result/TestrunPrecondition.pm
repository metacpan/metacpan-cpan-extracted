package Tapper::Schema::TestrunDB::Result::TestrunPrecondition;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::TestrunPrecondition::VERSION = '5.0.12';
# ABSTRACT: Tapper - Containg relations between testruns and preconditions

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("testrun_precondition");
__PACKAGE__->add_columns
    (
     "testrun_id",      { data_type => "INT", default_value => undef, is_nullable => 0, size => 11, is_foreign_key => 1, },
     "precondition_id", { data_type => "INT", default_value => undef, is_nullable => 0, size => 11, is_foreign_key => 1, },
     "succession",      { data_type => "INT", default_value => undef, is_nullable => 1, size => 10,                      },
    );

__PACKAGE__->set_primary_key(qw/testrun_id precondition_id/);

__PACKAGE__->belongs_to( testrun       => 'Tapper::Schema::TestrunDB::Result::Testrun',      { 'foreign.id' => 'self.testrun_id'      });
__PACKAGE__->belongs_to( precondition  => 'Tapper::Schema::TestrunDB::Result::Precondition', { 'foreign.id' => 'self.precondition_id' });

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::TestrunPrecondition - Tapper - Containg relations between testruns and preconditions

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
