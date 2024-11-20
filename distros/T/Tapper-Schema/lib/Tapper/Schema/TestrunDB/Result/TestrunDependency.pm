package Tapper::Schema::TestrunDB::Result::TestrunDependency;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::TestrunDependency::VERSION = '5.0.12';
# ABSTRACT: TestrunDependency - dependencies between testruns
# Testruns now can depend on each other with one testrun waiting until all the
# testruns it depends on have finished

use 5.010;
use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table("testrun_dependency");
__PACKAGE__->add_columns
  (
    dependee_testrun_id => {
      data_type => "INT",
      default_value => undef,
      is_nullable => 0,
      size => 11,
    },
    depender_testrun_id => {
      data_type => "INT",
      default_value => undef,
      is_nullable => 0,
      size => 11,
    },
  );

__PACKAGE__->set_primary_key("dependee_testrun_id","depender_testrun_id");

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->belongs_to(
  dependee => "${basepkg}::Testrun",
  { 'foreign.id' => 'self.dependee_testrun_id' },
  { on_delete => 'CASCADE' },
);

__PACKAGE__->belongs_to(
  depender => "${basepkg}::Testrun",
  { 'foreign.id' => 'self.depender_testrun_id' },
  { on_delete => 'CASCADE' },
);

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::TestrunDependency - TestrunDependency - dependencies between testruns

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
