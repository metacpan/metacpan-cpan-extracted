package Reaction::Test::WithDB;

use base qw/Reaction::Test/;
use Reaction::Class;

has 'schema' => (
  isa => 'DBIx::Class::Schema', is => 'rw',
  set_or_lazy_build('schema')
);

has 'schema_class' => (
  isa => 'Str', is => 'rw', set_or_lazy_fail('schema_class')
);

has 'connect_info' => (
  isa => 'ArrayRef', is => 'rw', required => 1, lazy => 1,
  default => sub { [ 'dbi:SQLite:t/var/reaction_test_withdb.db' ] },
);

override 'new' => sub {
  my $self = super();
  $self->BUILDALL;
  return $self;
};

sub BUILD {
  my ($self) = @_;
  my $schema = $self->schema_class->connect(@{$self->connect_info});
  $schema->deploy({ add_drop_table => 1 });
  $schema->setup_test_data if $schema->can('setup_test_data');
  $self->schema($schema);
}

1;

=head1 NAME

Reaction::Test::WithDB

=head1 DESCRIPTION

=head2 new

=head2 BUILD

Deploys database schema, dropping tables if they already exist.

=head1 ATTRIBUTES

=head2 schema

L<DBIx::Class::Schema>

=head2 schema_class

=head2 connect_info

Uses C<[ dbi:SQLite:t/var/reaction_test_withdb.db ]> by default.

=head1 SEE ALSO

L<Reaction::Test>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
