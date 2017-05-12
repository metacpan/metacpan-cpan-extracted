package Mojo::PgX::Cursor::Database;

require Mojo::PgX::Cursor::Cursor;
require Mojo::PgX::Cursor::Results;

use Mojo::Base 'Mojo::Pg::Database';

sub cursor {
  my $cursor = Mojo::PgX::Cursor::Cursor->new(
    db    => shift,
    query => shift,
    bind  => \@_,
  );
  return Mojo::PgX::Cursor::Results->new(cursor => $cursor);
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::PgX::Cursor::Database

=head1 DESCRIPTION

Subclass of L<Mojo::Pg::Database>.  Adds the C<cursor> method.

=head1 METHODS

=head2 cursor

    my $results = $db->cursor('select * from foo');
    my $results = $db->cursor('select * from foo where id >= (?)', 10);

Create a PostgreSQL cursor and return an L<Mojo::PgX::Cursor::Results> object.

=head1 LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nathaniel Nutter C<nnutter@cpan.org>

=head1 SEE ALSO

L<Mojo::PgX::Cursor>, L<Mojo::PgX::Cursor::Cursor>, L<Mojo::PgX::Cursor::Results>

=cut
