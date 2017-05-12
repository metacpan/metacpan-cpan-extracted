package SQL::ReservedWords::SQLite;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant SQLITE2 => 0x01; # 2.8.17
use constant SQLITE3 => 0x02; # 3.3.4

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_sqlite2
        is_reserved_by_sqlite3
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ALL                  => SQLITE2 | SQLITE3,
        ALTER                =>           SQLITE3,
        AND                  => SQLITE2 | SQLITE3,
        AS                   => SQLITE2 | SQLITE3,
        AUTOINCREMENT        =>           SQLITE3,
        BETWEEN              => SQLITE2 | SQLITE3,
        BY                   => SQLITE2 | SQLITE3,
        CASE                 => SQLITE2 | SQLITE3,
        CHECK                => SQLITE2 | SQLITE3,
        COLLATE              => SQLITE2 | SQLITE3,
        COMMIT               => SQLITE2 | SQLITE3,
        CONSTRAINT           => SQLITE2 | SQLITE3,
        CREATE               => SQLITE2 | SQLITE3,
        CROSS                =>           SQLITE3,
        DEFAULT              => SQLITE2 | SQLITE3,
        DEFERRABLE           => SQLITE2 | SQLITE3,
        DELETE               => SQLITE2 | SQLITE3,
        DISTINCT             => SQLITE2 | SQLITE3,
        DROP                 => SQLITE2 | SQLITE3,
        ELSE                 => SQLITE2 | SQLITE3,
        ESCAPE               =>           SQLITE3,
        EXCEPT               => SQLITE2 | SQLITE3,
        FOREIGN              => SQLITE2 | SQLITE3,
        FROM                 => SQLITE2 | SQLITE3,
        FULL                 =>           SQLITE3,
        GLOB                 => SQLITE2,
        GROUP                => SQLITE2 | SQLITE3,
        HAVING               => SQLITE2 | SQLITE3,
        IN                   => SQLITE2 | SQLITE3,
        INDEX                => SQLITE2 | SQLITE3,
        INNER                =>           SQLITE3,
        INSERT               => SQLITE2 | SQLITE3,
        INTERSECT            => SQLITE2 | SQLITE3,
        INTO                 => SQLITE2 | SQLITE3,
        IS                   => SQLITE2 | SQLITE3,
        ISNULL               => SQLITE2 | SQLITE3,
        JOIN                 => SQLITE2 | SQLITE3,
        LEFT                 =>           SQLITE3,
        LIKE                 => SQLITE2,
        LIMIT                => SQLITE2 | SQLITE3,
        NATURAL              =>           SQLITE3,
        NOT                  => SQLITE2 | SQLITE3,
        NOTNULL              => SQLITE2 | SQLITE3,
        NULL                 => SQLITE2 | SQLITE3,
        ON                   => SQLITE2 | SQLITE3,
        OR                   => SQLITE2 | SQLITE3,
        ORDER                => SQLITE2 | SQLITE3,
        OUTER                =>           SQLITE3,
        PRIMARY              => SQLITE2 | SQLITE3,
        REFERENCES           => SQLITE2 | SQLITE3,
        RIGHT                =>           SQLITE3,
        ROLLBACK             => SQLITE2 | SQLITE3,
        SELECT               => SQLITE2 | SQLITE3,
        SET                  => SQLITE2 | SQLITE3,
        TABLE                => SQLITE2 | SQLITE3,
        THEN                 => SQLITE2 | SQLITE3,
        TO                   =>           SQLITE3,
        TRANSACTION          => SQLITE2 | SQLITE3,
        UNION                => SQLITE2 | SQLITE3,
        UNIQUE               => SQLITE2 | SQLITE3,
        UPDATE               => SQLITE2 | SQLITE3,
        USING                => SQLITE2 | SQLITE3,
        VALUES               => SQLITE2 | SQLITE3,
        WHEN                 => SQLITE2 | SQLITE3,
        WHERE                => SQLITE2 | SQLITE3,
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_sqlite2 {
        return &is_reserved & SQLITE2;
    }

    sub is_reserved_by_sqlite3 {
        return &is_reserved & SQLITE3;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'SQLite 2' if $flags & SQLITE2;
        push @reserved_by, 'SQLite 3' if $flags & SQLITE3;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::SQLite - Reserved SQL words by SQLite

=head1 SYNOPSIS

   if ( SQL::ReservedWords::SQLite->is_reserved( $word ) ) {
       print "$word is a reserved SQLite word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by SQLite.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by either SQLite 2 or 3.

=item is_reserved_by_sqlite2( $word )

Returns a boolean indicating if C<$word> is reserved by SQLite 2.

=item is_reserved_by_sqlite3( $word )

Returns a boolean indicating if C<$word> is reserved by SQLite 3.

=item reserved_by( $word )

Returns a list with SQLite versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_sqlite2

=item is_reserved_by_sqlite3

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords>

L<http://www.sqlite.org/docs.html>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
