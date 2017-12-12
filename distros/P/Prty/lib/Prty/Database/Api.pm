package Prty::Database::Api;
use base qw/Prty::Object/;

use strict;
use warnings;

our $VERSION = 1.121;

use Prty::Database::Api::Dbi::Connection;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Database::Api - Lowlevel Datenbank-Schnittstelle

=head1 BASE CLASS

L<Prty::Object>

=head1 DESCRIPTION

Eine grundlegende Datenbank-Schnittstelle Prty::Database::Api::*
wird durch zwei Klassen definiert:

Prty::Database::Api::*::Connection

    $db = $class->new($udlObj);  # Datenbankverbindung aufbauen
    $cur = $db->sql($stmt);      # SQL-Statement ausführen
    $db->destroy;                # Datenbankverbindung abbauen

Prty::Database::Api::*::Cursor

    $cur = $class->new(@keyVal); # Curson instantiieren
    
    $n = $cur->bindVars;         # Anzahl Bind-Variablen
    $n = $cur->hits;             # Anzahl "Treffer"
    $id = $cur->id;              # Generierter Autoinkrement-Wert
    $titlesA = $cur->titles;     # Kolumnentitel
    
    $cur2 = $cur->bind(@vals);   # Platzhalter einsetzen
    $row = $cur->fetch;          # nächsten Datensatz lesen
    
    $cur->destroy;               # Cursor schließen

Die bislang einzige Lowlevel-Datenbank-Schnittstelle ist DBI, die
die beiden Klassen umfasst:

    Prty::Database::Api::Dbi::Connection
    Prty::Database::Api::Dbi::Cursor

Potentielle andere Lowlevel-Datenbank-Schnittstellen müssen
die gleichen Methoden implementieren.

=head1 METHODS

=head2 Verbindungsaufbau

=head3 connect() - Instantiiere Lowlevel-Datenbankverbindung

=head4 Synopsis

    $db = $class->connect($udlObj);

=head4 Description

Instantiiere eine Lowlevel-Datenbankverbindung auf Basis von
UDL-Objekt $udlObj und liefere eine Referenz auf die
Datenbankverbindung zurück.

=head4 Example

    use Prty::Database::Api;
    
    my $udl = 'dbi#mysql:test%root';
    my $udlObj = Prty::Udl->new($udl);
    my $db = Prty::Database::Api->connect($udlObj);
    print ref($db),"\n";
    __END__
    Prty::Database::Api::Dbi::Connection

=cut

# -----------------------------------------------------------------------------

sub connect {
    my $class = shift;
    my ($udlObj) = @_;

    my $apiName = ucfirst $udlObj->api;
    my $apiClass = $class.'::'.$apiName.'::Connection';

    return $apiClass->new(@_);
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.121

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
