package Mojo::DB::Results::Role::Struct;

use Mojo::Base -role;
use Mojo::Util qw(encode sha1_sum);
use Struct::Dumb 'readonly_struct';

our $VERSION = 'v0.1.1';

requires qw(array arrays columns);

sub struct { my $r = $_[0]->array // return undef; $_[0]->_struct->(@$r) }

sub structs {
  my $self = shift;
  my $struct = $self->_struct;
  return $self->arrays->map(sub { $struct->(@$_) });
}

sub _struct {
  my $self = shift;
  my $cols = $self->columns;
  my $name = 'RowStruct_' . sha1_sum(join "\0", map { encode 'UTF-8', $_ } @$cols);
  return $self->{_struct} if defined($self->{_struct} = __PACKAGE__->can($name));
  readonly_struct $name => $cols;
  return $self->{_struct} = __PACKAGE__->can($name);
}

1;

=head1 NAME

Mojo::DB::Results::Role::Struct - Database query results as structs

=head1 SYNOPSIS

  use Mojo::SQLite;
  my $sqlite = Mojo::SQLite->new(...);
  my $results = $sqlite->db->query('SELECT * FROM "table" WHERE "foo" = ?', 42);
  my $struct = $results->with_roles('Mojo::DB::Results::Role::Struct')->structs->first;
  my $bar = $struct->bar; # dies unless column "bar" exists

  use Mojo::Pg;
  my $pg = Mojo::Pg->new(...)->with_roles('Mojo::DB::Role::ResultsRoles');
  push @{$pg->results_roles}, 'Mojo::DB::Results::Role::Struct';
  my $results = $pg->db->query('SELECT "foo", "bar" FROM "table"');
  foreach my $row ($results->structs->each) {
    my $foo = $row->foo;
    my $bar = $row->baz; # dies
  }

=head1 DESCRIPTION

This role can be applied to a results object for L<Mojo::Pg> or similar
database APIs. It provides L</"struct"> and L</"structs"> methods which return
L<Struct::Dumb> records, providing read-only accessors only for the expected
column names. Note that a column name that is not a valid identifier is
trickier to access in this manner.

  my $row = $results->struct;
  my $col_name = 'foo.bar';
  my $val = $row->$col_name;
  # or
  my $val = $row->${\'foo.bar'};

You can apply the role to a results object using L<Mojo::Base/"with_roles">,
or apply it to all results objects created by a database manager using
L<Mojo::DB::Role::ResultsRoles> as shown in the synopsis.

=head1 METHODS

L<Mojo::DB::Results::Role::Struct> composes the following methods.

=head2 struct

  my $struct = $results->struct;

Fetch next row from the statement handle with the result object's C<array>
method, and return it as a struct.

=head2 structs

  my $collection = $results->structs;

Fetch all rows from the statement handle with the result object's C<arrays>
method, and return them as a L<Mojo::Collection> object containing structs.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::DB::Role::ResultsRoles>, L<Mojo::Pg>, L<Mojo::SQLite>, L<Mojo::mysql>
