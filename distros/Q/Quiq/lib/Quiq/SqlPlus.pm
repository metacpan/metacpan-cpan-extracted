package Quiq::SqlPlus;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Unindent;
use Quiq::Option;
use Quiq::Template;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::SqlPlus - Erzeuge Code für SQL*Plus

=head1 BASE CLASS

L<Quiq::Object>

=head1 EXAMPLE

Der Aufruf

    my $script = Quiq::SqlPlus->script('test.sql',q|
            SELECT
                *
            FROM
                all_users
            ORDER BY
                username
            ;
        |,
        -before => q|
            SELECT
                SYSDATE AS t0
            FROM
                dual
            ;
        |,
        -after => q|
            SELECT
                SYSDATE AS t1
            FROM
                dual
            ;
        |,
        -author => 'Frank Seitz',
        -description => q|
            Dies ist ein Test-Skript.
        |,
    );

erzeugt

    -- NAME
    --     test.sql
    --
    -- DESCRIPTION
    --     Dies ist ein Test-Skript.
    --
    -- AUTHOR
    --     Frank Seitz
    
    COLUMN tempdatum NEW_VALUE startdatum NOPRINT
    
    SELECT
        TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') AS tempdatum
    FROM
        dual;
    
    SPOOL test.sql.&&startdatum..log
    
    SET ECHO ON
    SET FEEDBACK ON
    SET VERIFY OFF
    SET HEADING ON
    SET TAB OFF
    SET PAGESIZE 0
    SET TRIMSPOOL ON
    SET LINESIZE 10000
    SET SERVEROUTPUT ON SIZE 10000
    SET SQLBLANKLINES ON
    SET TIMING ON
    
    WHENEVER OSERROR EXIT FAILURE ROLLBACK
    WHENEVER SQLERROR EXIT FAILURE ROLLBACK
    
    ALTER SESSION SET NLS_NUMERIC_CHARACTERS=",.";
    ALTER SESSION set NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
    
    -- ZUSTAND ZUVOR
    
    SELECT
        SYSDATE AS t0
    FROM
        dual
    ;
    
    -- OPERATION
    
    SELECT
        *
    FROM
        all_users
    ORDER BY
        username
    ;
    
    -- ZUSTAND DANACH
    
    SELECT
        SYSDATE AS t1
    FROM
        dual
    ;
    
    ROLLBACK;
    
    EXIT
    
    -- eof

=head1 METHODS

=head2 Klassenmethoden

=head3 script() - Erzeuge SQL*Plus-Skript

=head4 Synopsis

    $script = $class->script($name,$sql,@opt);

=head4 Arguments

=over 4

=item $name

Name des Skripts. Der Name wird in einen Kommentar an den Anfang
des Skripts gesetzt und für die Benennung der Logdatei genutzt

    NAME-YYYYMMDDHHMMSS.log

wobei der Zeitanteil beim Aufruf des Skripts gesetzt wird.

=item $sql

Der SQL*Plus-Code, der in den Rumpf des Skripts eingesetzt wird.

=back

=head4 Options

=over 4

=item -author => $author

Name des Skript-Autors, z.B. "Frank Seitz".

=item -description => $description

Beschreibung des Skripts. Darf mehrzeilig sein.

=item -commit => $bool (Default: 0)

Wenn diese Option gesetzt ist, wird COMMIT ans Ende des
Skripots gesetzt, sonst ROLLBACK.

=item -before => $sql

SQL*Plus-Code, der I<vor> $sql ausgeführt wird.

=item -beforeAndAfter => $sql

SQL*Plus-Code, der vor I<und> nach $sql ausgeführt wird.

=item -after => $sql

SQL*Plus-Code, der I<nach> $sql ausgeführt wird.

=back

=cut

# -----------------------------------------------------------------------------

sub script {
    my $class = shift;
    my $name = shift;
    my $sql = Quiq::Unindent->trim(shift);
    # @_: @opt

    my $author = undef;
    my $description = undef;
    my $commit = 0;
    my $before = undef;
    my $beforeAndAfter = undef;
    my $after = undef;
    my $help = 0;

    Quiq::Option->extract(\@_,
        -author => \$author,
        -description => \$description,
        -commit => \$commit,
        -before => \$before,
        -beforeAndAfter => \$beforeAndAfter,
        -after => \$after,
        -help => \$help,
    );

    my $template = Quiq::Unindent->string(q|
        __COMMENT__

        COLUMN tempdatum NEW_VALUE startdatum NOPRINT

        SELECT
            TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') AS tempdatum
        FROM
            dual;

        SPOOL __NAME__.&&startdatum..log

        SET ECHO ON
        SET FEEDBACK ON
        SET VERIFY OFF
        SET HEADING ON
        SET TAB OFF
        SET PAGESIZE 0
        SET TRIMSPOOL ON
        SET LINESIZE 2100
        SET SQLBLANKLINES ON
        SET TIMING ON

        WHENEVER OSERROR EXIT FAILURE ROLLBACK
        WHENEVER SQLERROR EXIT FAILURE ROLLBACK

        ALTER SESSION SET NLS_NUMERIC_CHARACTERS=",.";
        ALTER SESSION set NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

        __SQL__

        EXIT

        -- eof
    |);

    my $tpl = Quiq::Template->new('text',\$template);

    my $comment = Quiq::Unindent->string("
        -- NAME
        --     $name
    ");
    if ($description) {
        $description = Quiq::Unindent->trim($description);
        $description =~ s/^/--     /mg;
        $comment .= "--\n-- DESCRIPTION\n$description\n";
    }
    if ($author) {
        $author = Quiq::Unindent->trim($author);
        $author =~ s/^/--     /mg;
        $comment .= "--\n-- AUTHOR\n$author\n";
    }

    if ($before || $after || $beforeAndAfter) {
        $sql = "-- OPERATION\n\n$sql";
    }
    if ($beforeAndAfter) {
        $beforeAndAfter = Quiq::Unindent->trim($beforeAndAfter);
        if ($before) {
            $before .= "\n";
        }
        $before .= $beforeAndAfter;
        if ($after) {
            $after .= "\n";
        }
        $after .= $beforeAndAfter;
    }
    if ($before) {
        $before = Quiq::Unindent->trim($before);
        $sql =
            "-- ZUSTAND VORHER\n\n$before\n\n$sql";
    }
    if ($after) {
        $after = Quiq::Unindent->trim($after);
        $sql =
            "$sql\n\n-- ZUSTAND NACHHER\n\n$after\n";
    }
    if ($commit) {
        $sql .= "\nCOMMIT;\n";
    }
    else {
        $sql .= "\nROLLBACK;\n";
    }

    $tpl->replace(
        __COMMENT__ => $comment,
        __NAME__ => $name,
        __SQL__ => $sql,
    );

    return $tpl->asStringNL;
}
    

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
