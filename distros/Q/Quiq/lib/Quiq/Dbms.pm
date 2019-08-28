package Quiq::Dbms;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.155';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Dbms - Datenbanksystem

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

    use Quiq::Dbms;
    
    # Instantiierung
    my $d = Quiq::Dbms->new($dbms);
    
    # Namen der bekannten Datensysteme
    my @names = Quiq::Dbms->dbmsNames;
    
    # Boolsche Werte für Tests
    ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql) = $d->dbmsVector;
    
    # Testmethoden
    
    $bool = $d->isOracle;
    $bool = $d->isPostgreSQL;
    $bool = $d->isSQLite;
    $bool = $d->isMySQL;
    $bool = $d->isAccess;
    $bool = $d->isMSSQL;

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Datenbanksystem, bestehend
(lediglich) aus dem Namen des Datenbanksystems und dessen Version.
Die Klasse stellt Testmethoden für die Art des DBMS zur Verfügung
und ist daher vor allem als Basisklasse nützlich, z.B. für Klassen,
die SQL-Code generieren oder analysieren.

=head1 ATTRIBUTES

=over 4

=item dbms => $dbmsName

Name des DBMS.

=item version => $version

Versionsnummer des DBMS.

=back

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

    $d = $class->new($dbms);
    $d = $class->new($dbms,$version);

=head4 Arguments

=over 4

=item $dbms

Name des DBMS.

=item $version

Versionsnummer des DBMS.

=back

=head4 Returns

DBMS-Objekt

=head4 Description

Instantiiere ein DBMS-Objekt für DBMS $dbms und liefere eine
Referenz auf dieses Objekt zurück. Die Liste der unterstützten
DBMSe siehe $class->L<dbmsNames|"dbmsNames() - Liste der Namen der unterstützten Datenbanksysteme">().

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dbms,$version) = @_;

    # DBMS-Name case-insensitiv suchen

    my $dbmsName;
    for ($class->dbmsNames) {
        if (lc($dbms) eq lc($_)) {
            $dbmsName = $_;
            last;
        }
    }
    if (!$dbmsName) {
        $class->throw(
            '-00001: Unknown DBMS',
            Dbms => $dbms,
        );
    }

    # Objekt instantiieren

    return $class->SUPER::new(
        dbms => $dbmsName,
        version => $version,
    );
}

# -----------------------------------------------------------------------------

=head3 dbmsNames() - Liste der Namen der unterstützten Datenbanksysteme

=head4 Synopsis

    $namesA | @names = $this->dbmsNames;

=head4 Description

Liefere folgende Liste von DBMS-Namen (in dieser Reihenfolge):

    Oracle
    PostgreSQL
    SQLite
    MySQL
    Access
    MSSQL

=cut

# -----------------------------------------------------------------------------

my @DbmsNames = qw/Oracle PostgreSQL SQLite MySQL Access MSSQL/;

sub dbmsNames {
    my $this = shift;
    return wantarray? @DbmsNames: \@DbmsNames;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 dbmsTestVector() - Vektor für DBMS-Tests

=head4 Synopsis

    ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql) = $d->dbmsTestVector;

=head4 Description

Liefere einen Vektor von boolschen Werten, von denen genau einer den
Wert "wahr" besitzt, und zwar der, der dem DBMS entspricht,
auf den das Objekt instantiiert ist.

Die Methode ist für Programmcode nützlich, der DBMS-spezifische
Unterscheidungen macht. Der Code braucht dann lediglich auf den
Wert einer Variable prüfen

    if ($oracle) ...

statt einen umständlichen und fehleranfälligen Stringvergleich
durchzuführen

    if ($dbms eq 'Oracle') ...

=cut

# -----------------------------------------------------------------------------

sub dbmsTestVector {
    my $self = shift;
    return map { $_ eq $self->{'dbms'}? 1: 0 } $self->dbmsNames;
}

# -----------------------------------------------------------------------------

=head3 isOracle() - Teste auf Oracle

=head4 Synopsis

    $bool = $d->isOracle;

=cut

# -----------------------------------------------------------------------------

sub isOracle {
    my $self = shift;
    return $self->{'dbms'} eq 'Oracle'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isPostgreSQL() - Teste auf PostgreSQL

=head4 Synopsis

    $bool = $d->isPostgreSQL;

=cut

# -----------------------------------------------------------------------------

sub isPostgreSQL {
    my $self = shift;
    return $self->{'dbms'} eq 'PostgreSQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isSQLite() - Teste auf SQLite

=head4 Synopsis

    $bool = $d->isSQLite;

=cut

# -----------------------------------------------------------------------------

sub isSQLite {
    my $self = shift;
    return $self->{'dbms'} eq 'SQLite'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isMySQL() - Teste auf MySQL

=head4 Synopsis

    $bool = $d->isMySQL;

=cut

# -----------------------------------------------------------------------------

sub isMySQL {
    my $self = shift;
    return $self->{'dbms'} eq 'MySQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isAccess() - Teste auf Access

=head4 Synopsis

    $bool = $d->isAccess;

=cut

# -----------------------------------------------------------------------------

sub isAccess {
    my $self = shift;
    return $self->{'dbms'} eq 'Access'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isMSSQL() - Teste auf MSSQL

=head4 Synopsis

    $bool = $d->isMSSQL;

=cut

# -----------------------------------------------------------------------------

sub isMSSQL {
    my $self = shift;
    return $self->{'dbms'} eq 'MSSQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.155

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
