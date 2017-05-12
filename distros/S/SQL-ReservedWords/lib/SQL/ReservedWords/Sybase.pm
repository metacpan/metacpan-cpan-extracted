package SQL::ReservedWords::Sybase;

use strict;
use warnings;
use vars '$VERSION';

$VERSION = '0.8';

use constant SYBASEASE12 => 0x01;
use constant SYBASEASE15 => 0x02;

{
    require Sub::Exporter;

    my @exports = qw[
        is_reserved
        is_reserved_by_ase12
        is_reserved_by_ase15
        reserved_by
        words
    ];

    Sub::Exporter->import( -setup => { exports => \@exports } );
}

{
    my %WORDS = (
        ADD                  => SYBASEASE12 | SYBASEASE15,
        ALL                  => SYBASEASE12 | SYBASEASE15,
        ALTER                => SYBASEASE12 | SYBASEASE15,
        AND                  => SYBASEASE12 | SYBASEASE15,
        ANY                  => SYBASEASE12 | SYBASEASE15,
        ARITH_OVERFLOW       => SYBASEASE12 | SYBASEASE15,
        AS                   => SYBASEASE12 | SYBASEASE15,
        ASC                  => SYBASEASE12 | SYBASEASE15,
        AT                   => SYBASEASE12 | SYBASEASE15,
        AUTHORIZATION        => SYBASEASE12 | SYBASEASE15,
        AVG                  => SYBASEASE12 | SYBASEASE15,
        BEGIN                => SYBASEASE12 | SYBASEASE15,
        BETWEEN              => SYBASEASE12 | SYBASEASE15,
        BREAK                => SYBASEASE12 | SYBASEASE15,
        BROWSE               => SYBASEASE12 | SYBASEASE15,
        BULK                 => SYBASEASE12 | SYBASEASE15,
        BY                   => SYBASEASE12 | SYBASEASE15,
        CASCADE              => SYBASEASE12 | SYBASEASE15,
        CASE                 => SYBASEASE12 | SYBASEASE15,
        CHAR_CONVERT         => SYBASEASE12 | SYBASEASE15,
        CHECK                => SYBASEASE12 | SYBASEASE15,
        CHECKPOINT           => SYBASEASE12 | SYBASEASE15,
        CLOSE                => SYBASEASE12 | SYBASEASE15,
        CLUSTERED            => SYBASEASE12 | SYBASEASE15,
        COALESCE             => SYBASEASE12 | SYBASEASE15,
        COMMIT               => SYBASEASE12 | SYBASEASE15,
        COMPUTE              => SYBASEASE12 | SYBASEASE15,
        CONFIRM              => SYBASEASE12 | SYBASEASE15,
        CONNECT              => SYBASEASE12 | SYBASEASE15,
        CONSTRAINT           => SYBASEASE12 | SYBASEASE15,
        CONTINUE             => SYBASEASE12 | SYBASEASE15,
        CONTROLROW           => SYBASEASE12 | SYBASEASE15,
        CONVERT              => SYBASEASE12 | SYBASEASE15,
        COUNT                => SYBASEASE12 | SYBASEASE15,
        COUNT_BIG            =>               SYBASEASE15,
        CREATE               => SYBASEASE12 | SYBASEASE15,
        CURRENT              => SYBASEASE12 | SYBASEASE15,
        CURSOR               => SYBASEASE12 | SYBASEASE15,
        DATABASE             => SYBASEASE12 | SYBASEASE15,
        DBCC                 => SYBASEASE12 | SYBASEASE15,
        DEALLOCATE           => SYBASEASE12 | SYBASEASE15,
        DECLARE              => SYBASEASE12 | SYBASEASE15,
        DECRYPT              =>               SYBASEASE15,
        DEFAULT              => SYBASEASE12 | SYBASEASE15,
        DELETE               => SYBASEASE12 | SYBASEASE15,
        DESC                 => SYBASEASE12 | SYBASEASE15,
        DETERMINISTIC        => SYBASEASE12 | SYBASEASE15,
        DISK                 => SYBASEASE12 | SYBASEASE15,
        DISTINCT             => SYBASEASE12 | SYBASEASE15,
        DOUBLE               => SYBASEASE12,
        DROP                 => SYBASEASE12 | SYBASEASE15,
        DUMMY                => SYBASEASE12 | SYBASEASE15,
        DUMP                 => SYBASEASE12 | SYBASEASE15,
        ELSE                 => SYBASEASE12 | SYBASEASE15,
        ENCRYPT              =>               SYBASEASE15,
        END                  => SYBASEASE12 | SYBASEASE15,
        ENDTRAN              => SYBASEASE12 | SYBASEASE15,
        ERRLVL               => SYBASEASE12 | SYBASEASE15,
        ERRORDATA            => SYBASEASE12 | SYBASEASE15,
        ERROREXIT            => SYBASEASE12 | SYBASEASE15,
        ESCAPE               => SYBASEASE12 | SYBASEASE15,
        EXCEPT               => SYBASEASE12 | SYBASEASE15,
        EXCLUSIVE            => SYBASEASE12 | SYBASEASE15,
        EXEC                 => SYBASEASE12 | SYBASEASE15,
        EXECUTE              => SYBASEASE12 | SYBASEASE15,
        EXISTS               => SYBASEASE12 | SYBASEASE15,
        EXIT                 => SYBASEASE12 | SYBASEASE15,
        EXP_ROW_SIZE         => SYBASEASE12 | SYBASEASE15,
        EXTERNAL             => SYBASEASE12 | SYBASEASE15,
        FETCH                => SYBASEASE12 | SYBASEASE15,
        FILLFACTOR           => SYBASEASE12 | SYBASEASE15,
        FOR                  => SYBASEASE12 | SYBASEASE15,
        FOREIGN              => SYBASEASE12 | SYBASEASE15,
        FROM                 => SYBASEASE12 | SYBASEASE15,
        FUNC                 => SYBASEASE12,
        GOTO                 => SYBASEASE12 | SYBASEASE15,
        GRANT                => SYBASEASE12 | SYBASEASE15,
        GROUP                => SYBASEASE12 | SYBASEASE15,
        HAVING               => SYBASEASE12 | SYBASEASE15,
        HOLDLOCK             => SYBASEASE12 | SYBASEASE15,
        IDENTITY             => SYBASEASE12 | SYBASEASE15,
        IDENTITY_GAP         => SYBASEASE12 | SYBASEASE15,
        IDENTITY_INSERT      => SYBASEASE12,
        IDENTITY_START       => SYBASEASE12 | SYBASEASE15,
        IF                   => SYBASEASE12 | SYBASEASE15,
        IN                   => SYBASEASE12 | SYBASEASE15,
        INDEX                => SYBASEASE12 | SYBASEASE15,
        INOUT                => SYBASEASE12 | SYBASEASE15,
        INSENSITIVE          =>               SYBASEASE15,
        INSERT               => SYBASEASE12 | SYBASEASE15,
        INSTALL              => SYBASEASE12 | SYBASEASE15,
        INTERSECT            => SYBASEASE12 | SYBASEASE15,
        INTO                 => SYBASEASE12 | SYBASEASE15,
        IS                   => SYBASEASE12 | SYBASEASE15,
        ISOLATION            => SYBASEASE12 | SYBASEASE15,
        JAR                  => SYBASEASE12 | SYBASEASE15,
        JOIN                 => SYBASEASE12 | SYBASEASE15,
        KEY                  => SYBASEASE12 | SYBASEASE15,
        KILL                 => SYBASEASE12 | SYBASEASE15,
        LEVEL                => SYBASEASE12 | SYBASEASE15,
        LIKE                 => SYBASEASE12 | SYBASEASE15,
        LINENO               => SYBASEASE12 | SYBASEASE15,
        LOAD                 => SYBASEASE12 | SYBASEASE15,
        LOCK                 => SYBASEASE12 | SYBASEASE15,
        MATERIALIZED         =>               SYBASEASE15,
        MAX                  => SYBASEASE12 | SYBASEASE15,
        MAX_ROWS_PER_PAGE    => SYBASEASE12 | SYBASEASE15,
        MIN                  => SYBASEASE12 | SYBASEASE15,
        MIRROR               => SYBASEASE12 | SYBASEASE15,
        MIRROREXIT           => SYBASEASE12 | SYBASEASE15,
        MODIFY               => SYBASEASE12 | SYBASEASE15,
        NATIONAL             => SYBASEASE12 | SYBASEASE15,
        NEW                  => SYBASEASE12 | SYBASEASE15,
        NOHOLDLOCK           => SYBASEASE12 | SYBASEASE15,
        NONCLUSTERED         => SYBASEASE12 | SYBASEASE15,
        NONSCROLLABLE        =>               SYBASEASE15,
        NON_SENSITIVE        =>               SYBASEASE15,
        NOT                  => SYBASEASE12 | SYBASEASE15,
        NULL                 => SYBASEASE12 | SYBASEASE15,
        NULLIF               => SYBASEASE12 | SYBASEASE15,
        NUMERIC_TRUNCATION   => SYBASEASE12 | SYBASEASE15,
        OF                   => SYBASEASE12 | SYBASEASE15,
        OFF                  => SYBASEASE12 | SYBASEASE15,
        OFFSETS              => SYBASEASE12 | SYBASEASE15,
        ON                   => SYBASEASE12 | SYBASEASE15,
        ONCE                 => SYBASEASE12 | SYBASEASE15,
        ONLINE               => SYBASEASE12 | SYBASEASE15,
        ONLY                 => SYBASEASE12 | SYBASEASE15,
        OPEN                 => SYBASEASE12 | SYBASEASE15,
        OPTION               => SYBASEASE12 | SYBASEASE15,
        OR                   => SYBASEASE12 | SYBASEASE15,
        ORDER                => SYBASEASE12 | SYBASEASE15,
        OUT                  => SYBASEASE12 | SYBASEASE15,
        OUTPUT               => SYBASEASE12 | SYBASEASE15,
        OVER                 => SYBASEASE12 | SYBASEASE15,
        PARTITION            => SYBASEASE12 | SYBASEASE15,
        PERM                 => SYBASEASE12 | SYBASEASE15,
        PERMANENT            => SYBASEASE12 | SYBASEASE15,
        PLAN                 => SYBASEASE12 | SYBASEASE15,
        PRECISION            => SYBASEASE12,
        PREPARE              => SYBASEASE12 | SYBASEASE15,
        PRIMARY              => SYBASEASE12 | SYBASEASE15,
        PRINT                => SYBASEASE12 | SYBASEASE15,
        PRIVILEGES           => SYBASEASE12 | SYBASEASE15,
        PROC                 => SYBASEASE12 | SYBASEASE15,
        PROCEDURE            => SYBASEASE12 | SYBASEASE15,
        PROCESSEXIT          => SYBASEASE12 | SYBASEASE15,
        PROXY_TABLE          => SYBASEASE12 | SYBASEASE15,
        PUBLIC               => SYBASEASE12 | SYBASEASE15,
        QUIESCE              => SYBASEASE12 | SYBASEASE15,
        RAISERROR            => SYBASEASE12 | SYBASEASE15,
        READ                 => SYBASEASE12 | SYBASEASE15,
        READPAST             => SYBASEASE12 | SYBASEASE15,
        READTEXT             => SYBASEASE12 | SYBASEASE15,
        RECONFIGURE          => SYBASEASE12 | SYBASEASE15,
        REFERENCES           => SYBASEASE12 | SYBASEASE15,
        REMOVE               => SYBASEASE12 | SYBASEASE15,
        REORG                => SYBASEASE12 | SYBASEASE15,
        REPLACE              => SYBASEASE12 | SYBASEASE15,
        REPLICATION          => SYBASEASE12 | SYBASEASE15,
        RESERVEPAGEGAP       => SYBASEASE12 | SYBASEASE15,
        RETURN               => SYBASEASE12 | SYBASEASE15,
        RETURNS              => SYBASEASE12 | SYBASEASE15,
        REVOKE               => SYBASEASE12 | SYBASEASE15,
        ROLE                 => SYBASEASE12 | SYBASEASE15,
        ROLLBACK             => SYBASEASE12 | SYBASEASE15,
        ROWCOUNT             => SYBASEASE12 | SYBASEASE15,
        ROWS                 => SYBASEASE12 | SYBASEASE15,
        RULE                 => SYBASEASE12 | SYBASEASE15,
        SAVE                 => SYBASEASE12 | SYBASEASE15,
        SCHEMA               => SYBASEASE12 | SYBASEASE15,
        SCROLL               =>               SYBASEASE15,
        SCROLLABLE           =>               SYBASEASE15,
        SELECT               => SYBASEASE12 | SYBASEASE15,
        SEMI_SENSITIVE       =>               SYBASEASE15,
        SET                  => SYBASEASE12 | SYBASEASE15,
        SETUSER              => SYBASEASE12 | SYBASEASE15,
        SHARED               => SYBASEASE12 | SYBASEASE15,
        SHUTDOWN             => SYBASEASE12 | SYBASEASE15,
        SOME                 => SYBASEASE12 | SYBASEASE15,
        STATISTICS           => SYBASEASE12 | SYBASEASE15,
        STRINGSIZE           => SYBASEASE12 | SYBASEASE15,
        STRIPE               => SYBASEASE12 | SYBASEASE15,
        SUM                  => SYBASEASE12 | SYBASEASE15,
        SYB_IDENTITY         => SYBASEASE12 | SYBASEASE15,
        SYB_RESTREE          => SYBASEASE12 | SYBASEASE15,
        SYB_TERMINATE        => SYBASEASE12 | SYBASEASE15,
        TABLE                => SYBASEASE12 | SYBASEASE15,
        TEMP                 => SYBASEASE12 | SYBASEASE15,
        TEMPORARY            => SYBASEASE12 | SYBASEASE15,
        TEXTSIZE             => SYBASEASE12 | SYBASEASE15,
        TO                   => SYBASEASE12 | SYBASEASE15,
        TRACEFILE            =>               SYBASEASE15,
        TRAN                 => SYBASEASE12 | SYBASEASE15,
        TRANSACTION          => SYBASEASE12 | SYBASEASE15,
        TRIGGER              => SYBASEASE12 | SYBASEASE15,
        TRUNCATE             => SYBASEASE12 | SYBASEASE15,
        TSEQUAL              => SYBASEASE12 | SYBASEASE15,
        UNION                => SYBASEASE12 | SYBASEASE15,
        UNIQUE               => SYBASEASE12 | SYBASEASE15,
        UNPARTITION          => SYBASEASE12 | SYBASEASE15,
        UPDATE               => SYBASEASE12 | SYBASEASE15,
        USE                  => SYBASEASE12 | SYBASEASE15,
        USER                 => SYBASEASE12 | SYBASEASE15,
        USER_OPTION          => SYBASEASE12 | SYBASEASE15,
        USING                => SYBASEASE12 | SYBASEASE15,
        VALUES               => SYBASEASE12 | SYBASEASE15,
        VARYING              => SYBASEASE12 | SYBASEASE15,
        VIEW                 => SYBASEASE12 | SYBASEASE15,
        WAITFOR              => SYBASEASE12 | SYBASEASE15,
        WHEN                 => SYBASEASE12 | SYBASEASE15,
        WHERE                => SYBASEASE12 | SYBASEASE15,
        WHILE                => SYBASEASE12 | SYBASEASE15,
        WITH                 => SYBASEASE12 | SYBASEASE15,
        WORK                 => SYBASEASE12 | SYBASEASE15,
        WRITETEXT            => SYBASEASE12 | SYBASEASE15,
        XMLEXTRACT           =>               SYBASEASE15,
        XMLPARSE             =>               SYBASEASE15,
        XMLTEST              =>               SYBASEASE15,
        XMLVALIDATE          =>               SYBASEASE15,
    );

    sub is_reserved {
        return $WORDS{ uc(pop || '') } || 0;
    }

    sub is_reserved_by_ase12 {
        return &is_reserved & SYBASEASE12;
    }

    sub is_reserved_by_ase15 {
        return &is_reserved & SYBASEASE15;
    }

    sub reserved_by {
        my $flags       = &is_reserved;
        my @reserved_by = ();

        push @reserved_by, 'Sybase ASE 12' if $flags & SYBASEASE12;
        push @reserved_by, 'Sybase ASE 15' if $flags & SYBASEASE15;

        return @reserved_by;
    }

    sub words {
        return sort keys %WORDS;
    }
}

1;

__END__

=head1 NAME

SQL::ReservedWords::Sybase - Reserved SQL words by Sybase

=head1 SYNOPSIS

   if ( SQL::ReservedWords::Sybase->is_reserved( $word ) ) {
       print "$word is a reserved Sybase word!";
   }

=head1 DESCRIPTION

Determine if words are reserved by Sybase.

=head1 METHODS

=over 4

=item is_reserved( $word )

Returns a boolean indicating if C<$word> is reserved by either Sybase ASE 12 or 15.

=item is_reserved_by_ase12( $word )

Returns a boolean indicating if C<$word> is reserved by Sybase ASE 12.

=item is_reserved_by_ase15( $word )

Returns a boolean indicating if C<$word> is reserved by Sybase ASE 15.

=item reserved_by( $word )

Returns a list with Sybase versions that reserves C<$word>.

=item words

Returns a list with all reserved words.

=back

=head1 EXPORTS

Nothing by default. Following subroutines can be exported:

=over 4

=item is_reserved

=item is_reserved_by_ase12

=item is_reserved_by_ase15

=item reserved_by

=item words

=back

=head1 SEE ALSO

L<SQL::ReservedWords>

L<http://infocenter.sybase.com/help/>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
