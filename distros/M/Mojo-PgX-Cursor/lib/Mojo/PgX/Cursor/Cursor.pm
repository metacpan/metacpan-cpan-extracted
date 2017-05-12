package Mojo::PgX::Cursor::Cursor;

require UUID::Tiny;

use Mojo::Base -base;

has [qw(bind db name query)];

sub DESTROY {
  my $self = shift;
  if ($self->{close} && $self->db && $self->db->ping) { $self->close }
  return 1;
}

sub close {
  my $self = shift;
  my $query = sprintf('close %s', $self->db->dbh->quote_identifier($self->name));
  $self->db->query($query) if delete $self->{close};
}

sub fetch {
  my $self = shift;
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $fetch = shift || 100;
  my $query = sprintf('fetch %s from %s', $fetch, $self->db->dbh->quote_identifier($self->name));
  my @query_params = $query;
  push @query_params, $cb if $cb;
  return $self->db->query(@query_params);
}

sub new {
  my $self = shift->SUPER::new(
    bind => [],
    name => UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V4()),
    @_,
  );
  return unless defined $self->db
    and defined $self->query and length $self->query;
  my $query = sprintf('declare %s cursor with hold for %s',
    $self->db->dbh->quote_identifier($self->name), $self->query);
  $self->db->query($query, @{$self->bind});
  $self->{close} = 1;
  return $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::PgX::Cursor::Cursor

=head1 DESCRIPTION

L<Mojo::PgX::Cursor::Cursor> is a scope guard for L<DBD::Pg> cursors.

=head1 ATTRIBUTES

=head2 bind

    $cursor->bind([1, 2, 3]);

Bind values for the L</"query">.

=head2 db

    $cursor->db($pg->db);

The L<Mojo::Pg::Database> the L</"query"> will be run against.

=head2 name

    $cursor->name;

Name for the cursor.  If not set then a UUID will be used.

=head2 query

    $cursor->query('select * from foo');

SQL statement for the cursor.

=head1 METHODS

=head2 close

    $cursor->close

Close the cursor.

=head2 fetch

    my $results = $cursor->fetch;
    my $results = $cursor->fetch(10);

Fetch rows from the cursor.  Defaults to fetching 100 rows.

=head2 new

    my $cursor = Mojo::PgX::Cursor::Cursor->new(
      db => $pg->db,
      query => 'select * from foo',
    );

Construct a new L<Mojo::PgX::Cursor::Cursor> object.

=head1 LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nathaniel Nutter C<nnutter@cpan.org>

=head1 SEE ALSO

L<Mojo::PgX::Cursor>, L<Mojo::PgX::Cursor::Database>, L<Mojo::PgX::Cursor::Results>

=cut

