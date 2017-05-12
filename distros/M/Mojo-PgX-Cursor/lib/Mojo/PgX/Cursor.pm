package Mojo::PgX::Cursor;

require Mojo::PgX::Cursor::Database;

use Mojo::Base 'Mojo::Pg';

our $VERSION = "0.502001";

sub db {
    my $db = shift->SUPER::db(@_);
    return bless $db, 'Mojo::PgX::Cursor::Database';
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::PgX::Cursor - Cursor Extension for Mojo::Pg

=head1 SYNOPSIS

    my $pg = Mojo::PgX::Cursor->new('postgresql://postgres@/test');
    my $results = $pg->db->cursor('select * from some_big_table');
    while (my $next = $results->hash) {
      say $next->{name};
    }

=head1 DESCRIPTION

L<DBD::Pg> fetches all rows when a statement is executed whereas other drivers
usually fetch rows using the C<fetch*> methods.  Mojo::PgX::Cursor is an
extension to work around this issue using PostgreSQL cursors while providing a
L<Mojo::Pg>-style API for iteratoring over the results; see
L<Mojo::PgX::Cursor::Results> for details.

=head1 METHODS

=head2 db

This subclass overrides L<Mojo::Pg>'s implementation in order to subclass the
resulting L<Mojo::Pg::Database> object into a L<Mojo::PgX::Cursor::Database>.

=head1 VERSIONING

This module will follow L<Semantic Versioning
2.0.0|http://semver.org/spec/v2.0.0.html>.  Once the API feels reasonable I'll
release v1.0.0 which would correspond to 1.000000 according to L<version>,

    version->declare(q(v1.0.0))->numify # 1.000000
    version->parse(q(1.000000))->normal # v1.0.0

=head1 MONKEYPATCH

    require Mojo::Pg;
    require Mojo::PgX::Cursor;
    use Mojo::Util 'monkey_patch';
    monkey_patch 'Mojo::Pg::Database', 'cursor', \&Mojo::PgX::Cursor::Database::cursor;

Just because you can doesn't mean you should but if you want you can
C<monkey_patch> L<Mojo::Pg::Database> rather than swapping out your
construction of L<Mojo::Pg> objects with the L<Mojo::PgX::Cursor> subclass.

=head1 DISCUSSION

This module would be unnecessary if L<DBD::Pg> did not fetch all rows during
C<execute> and since C<libpq> supports that it would be much better to fix
C<fetch*> than to implement this.  However, I am not able to do so at this
time.

=head1 CONTRIBUTING

If you would like to submit bug reports, feature requests, questions, etc. you
should create an issue on the L<GitHub Issue
Tracker|https://github.com/nnutter/mojo-pgx-cursor/issues> for this module.

=head1 REFERENCES

=over

=item L<#93266 for DBD-Pg: DBD::Pg to set the fetch size|https://rt.cpan.org/Public/Bug/Display.html?id=93266>

=item L<#19488 for DBD-Pg: Support of cursor concept|https://rt.cpan.org/Public/Bug/Display.html?id=19488>

=back

=head1 LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nathaniel Nutter C<nnutter@cpan.org>

=head1 SEE ALSO

L<DBD::Pg>, L<Mojo::Pg>, L<Mojo::PgX::Cursor::Cursor>,
L<Mojo::PgX::Cursor::Database>, L<Mojo::PgX::Cursor::Results>

=cut

