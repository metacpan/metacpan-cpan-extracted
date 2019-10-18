package Quiq::PostgreSql::Catalog;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.160';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PostgreSql::Catalog - PostgreSQL Catalog-Operationen

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 correctFunctionDef() - Korrigiere Quelltext einer Funktionsdefinition

=head4 Synopsis

  $newSql = $class->correctFunctionDef($sql);

=head4 Arguments

=over 4

=item $sql

CREATE FUNCTION Statement, das von pg_get_function_identity_arguments(oid)
geliefert wurde.

=back

=head4 Returns

Umgeschriebenes CREATE FUNCTION Statement (String)

=head4 Description

PostgreSQL stellt die Funktion pg_get_functiondef() zur Verfügung,
die den Quelltext einer Datenbankfunktion liefert. Leider ist
der Quelltext manchmal fehlerbehaftet, zumindest in der Version 8.3.
Diese Methode korrigiert diese Fehler.

=cut

# -----------------------------------------------------------------------------

sub correctFunctionDef {
    my ($class,$sql) = @_;

    # 1) LANGUAGE korrigieren: Enthält der Quelltext kein BEGIN,
    # setzen wird sql statt plpgsql als Sprache.

    if ($sql !~ /BEGIN/) {
        $sql =~ s/plpgsql/sql/;
    }

    # 2) VOLATILESECURITY korrigieren: Der erzeugte Code enthält
    # gelegentlich den Ausdruck Q{VOLATILESECURITY}. Dieser ist syntaktisch
    # falsch, es muss Q{VOLATILE SECURITY} (zwei Worte) lauten.
    
    $sql =~ s/VOLATILESECURITY/VOLATILE SECURITY/i;

    # $sql =~ s/character varying\(-4\)/character varying(4)/ig;

    return $sql;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.160

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
