package Tapper::Schema::TestrunDB::Result::TestplanInstance;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::TestplanInstance::VERSION = '5.0.11';
# ABSTRACT: Tapper -

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table("testplan_instance");
__PACKAGE__->add_columns
  (
   "id",                 { data_type => "INT",       default_value => undef,                is_nullable => 0, size => 11, is_auto_increment => 1, },
   "path",               { data_type => "VARCHAR",   default_value => "",                   is_nullable => 1, size => 255, },
   "name",               { data_type => "VARCHAR",   default_value => "",                   is_nullable => 1, size => 255, },
   "evaluated_testplan", { data_type => "TEXT",      default_value => "",                   is_nullable => 1, },
   "created_at",         { data_type => "TIMESTAMP", default_value => \'CURRENT_TIMESTAMP', is_nullable => 1, },
   "updated_at",         { data_type => "DATETIME",  default_value => undef,                is_nullable => 1, },
    );

__PACKAGE__->has_many ( testruns => 'Tapper::Schema::TestrunDB::Result::Testrun', { 'foreign.testplan_id' => 'self.id'}, {cascade_delete => 0 });
__PACKAGE__->set_primary_key("id");

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::TestplanInstance - Tapper -

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
