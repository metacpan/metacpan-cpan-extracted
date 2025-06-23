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
  
  # Namen der unterstützten Datenbanksysteme
  my @names = Quiq::Dbms->dbmsNames;
  
  # Boolsche Variable für Tests
  
  ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql,$jdbc) =
      $d->dbmsTestVector;
  
  # Test-Methoden
  
  $bool = $d->isOracle;
  $bool = $d->isPostgreSQL;
  $bool = $d->isSQLite;
  $bool = $d->isMySQL;
  $bool = $d->isAccess;
  $bool = $d->isMSSQL;
  $bool = $d->isJDBC;

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

=cut

# -----------------------------------------------------------------------------

package Quiq::Dbms;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $d = $class->new($dbms);
  $d = $class->new($dbms,$version);
  $d = $class->new($db);

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
    my $class = shift;
    my $dbms = ref $_[0]? shift->dbms: shift;
    my $version = shift;

    # DBMS-Namen case insensitive suchen

    my ($dbmsName) = grep {lc($dbms) eq lc($_)} $class->dbmsNames;
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

=head2 Klassenmethoden

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
  JDBC

=cut

# -----------------------------------------------------------------------------

my @DbmsNames = qw/Oracle PostgreSQL SQLite MySQL Access MSSQL JDBC/;

sub dbmsNames {
    return wantarray? @DbmsNames: \@DbmsNames;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 dbmsTestVector() - Vektor für DBMS-Tests

=head4 Synopsis

  ($oracle,$postgresql,$sqlite,$mysql,$access,$mssql,$jdbc) = $d->dbmsTestVector;

=head4 Description

Liefere einen Vektor von boolschen Werten, von denen genau einer
wahr ist, und zwar derjenige, der dem DBMS entspricht, auf den das
Objekt instantiiert ist.

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
    return map {$_ eq $self->{'dbms'}? 1: 0} $self->dbmsNames;
}

# -----------------------------------------------------------------------------

=head3 isOracle() - Teste auf Oracle

=head4 Synopsis

  $bool = $d->isOracle;

=head4 Description

Prüfe, ob das Datenbanksystem Oracle ist. Wenn ja, liefere wahr,
sonst falsch.

=cut

# -----------------------------------------------------------------------------

sub isOracle {
    return shift->{'dbms'} eq 'Oracle'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isPostgreSQL() - Teste auf PostgreSQL

=head4 Synopsis

  $bool = $d->isPostgreSQL;

=head4 Description

Prüfe, ob das Datenbanksystem PostgreSQL ist. Wenn ja, liefere wahr,
sonst falsch.

=cut

# -----------------------------------------------------------------------------

sub isPostgreSQL {
    return shift->{'dbms'} eq 'PostgreSQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isSQLite() - Teste auf SQLite

=head4 Synopsis

  $bool = $d->isSQLite;

=head4 Description

Prüfe, ob das Datenbanksystem SQLite ist. Wenn ja, liefere wahr,
sonst falsch.

=cut

# -----------------------------------------------------------------------------

sub isSQLite {
    return shift->{'dbms'} eq 'SQLite'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isMySQL() - Teste auf MySQL

=head4 Synopsis

  $bool = $d->isMySQL;

=head4 Description

Prüfe, ob das Datenbanksystem MySQL ist. Wenn ja, liefere wahr,
sonst falsch.

=cut

# -----------------------------------------------------------------------------

sub isMySQL {
    return shift->{'dbms'} eq 'MySQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isAccess() - Teste auf Access

=head4 Synopsis

  $bool = $d->isAccess;

=head4 Description

Prüfe, ob das Datenbanksystem Access ist. Wenn ja, liefere wahr,
sonst falsch.

=cut

# -----------------------------------------------------------------------------

sub isAccess {
    return shift->{'dbms'} eq 'Access'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isMSSQL() - Teste auf MSSQL

=head4 Synopsis

  $bool = $d->isMSSQL;

=head4 Description

Prüfe, ob das Datenbanksystem MSSQL ist. Wenn ja, liefere wahr,
sonst falsch.

=cut

# -----------------------------------------------------------------------------

sub isMSSQL {
    return shift->{'dbms'} eq 'MSSQL'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isJDBC() - Teste auf JDBC

=head4 Synopsis

  $bool = $d->isJDBC;

=head4 Description

Prüfe, ob das Datenbanksystem JDBC ist. Wenn ja, liefere wahr,
sonst falsch.

=cut

# -----------------------------------------------------------------------------

sub isJDBC {
    return shift->{'dbms'} eq 'JDBC'? 1: 0;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
