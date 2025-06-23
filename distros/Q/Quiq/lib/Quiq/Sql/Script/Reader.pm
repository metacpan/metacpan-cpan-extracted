# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sql::Script::Reader - Leser von SQL-Skripten

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

  use Quiq::Sql::Script::Reader;
  
  my $rd = Quiq::Sql::Script::Reader->new($dbms,$file);
  while (my $stmt = $rd->nextStmt) {
      # irgendwas mit dem SQL-Statement machen
  }
  $rd->close;

=head1 DESCRIPTION

Die Klasse implementiert einen Leser von SQL-Skripten. Ein SQL-Skript
ist eine Folge von SQL-Statements, die mit Semikolon I<am Ende einer
Zeile> (also vor einem Newline) voneinander getrennt sind. Eine Instanz
der Klasse liefert nacheinander die einzelnen Statements, die ausgeführt
oder anderweitig verarbeitet werden können. Da das Skript sukzessive
gelesen wird, können auch sehr große SQL-Skripte, z.B. von
Datenbank-Dumps, durch die Klasse verarbeitet werden.

Leerzeilen am Anfang eines Statements werden entfernt, außerdem
das abschließende Semikolon und darauffolgender Whitespace bis
zum Zeilenende.

=head1 CAVEATS

Mehrere SQL-Statements I<auf einer Zeile> beherrscht die Klasse nicht.

=cut

# -----------------------------------------------------------------------------

package Quiq::Sql::Script::Reader;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Sql::Analyzer;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $rd = $class->new($dbms,$file,@opt);
  $rd = $class->new($dbms,\$str,@opt);

=head4 Arguments

=over 4

=item $dbms

Name des DBMS, das die SQL-Statements des Skripts ausführen kann.

=item $file

Dateipfad des SQL-Skripts. Im Falle von '-' wird von STDIN gelesen.

=item $str

Das SQL-Skript als Zeichenkette.

=back

=head4 Options

=over 4

=item -separator => $regex (Default: qr/;\s*$/)

Statement-Separator. Per Default ein Semikolon (;) am Zeilenende.
Andere Variante (geeigneter, wenn Prozeduren vorkommen können),
Semikolon allein auf Zeile: qr/^;\s*$/.

=back

=head4 Returns

Reader-Objekt

=head4 Description

Instantiiere ein Reader-Objekt für DBMS $dbms und Datei $file bzw.
Zeichenkette $str und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dbms,$input) = splice @_,0,3;

    my $separator = qr/\s*;$/;

    $class->parameters(\@_,
        -separator => \$separator,
    );

    # SQL-Analyzer instantiieren (mit Namensprüfung)
    my $aly = Quiq::Sql::Analyzer->new($dbms);

    my $fh = Quiq::FileHandle->new('<',$input);
    $fh->setEncoding('utf-8');

    return $class->SUPER::new(
        analyzer => $aly,
        fh => $fh,
        separator => $separator,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 close() - Beende Nutzung des Readers

=head4 Synopsis

  $rd->close;

=head4 Description

Beende die die Nutzung des Reader-Objekts. Nach Aufruf der Methode
kann der Reader nicht mehr genutzt werden.

=cut

# -----------------------------------------------------------------------------

sub close {
    $_[0]->{'fh'}->close;
    $_[0] = undef;
}

# -----------------------------------------------------------------------------

=head3 nextStmt() - Nächstes Statement

=head4 Synopsis

  $stmt = $rd->nextStmt;

=head4 Returns

SQL-Statemt (String)

=head4 Description

Liefere das nächste SQL-Statement des Skripts. Leere Statements werden
übergangen. Ist das Ende erreicht, liefere C<undef>.

=cut

# -----------------------------------------------------------------------------

sub nextStmt {
    my $self = shift;

    my ($fh,$aly,$separator) = $self->get('fh','analyzer','separator');

    my $stmt;
    while (<$fh>) {
        if (s/^---+$//) {
            # Eine Trennlinie übergehen wir
            next;
        }
        $stmt .= $_;
        if (/$separator/) {
            if ($stmt =~ /^[\s;]*$/) {
                # Leere Statements übergehen wir
                $stmt = undef;
                next;
            }

            if ($aly->isCreateFunction($stmt)) {

                # Im Falle von CREATE FUNCTION oder CREATE OR REPLACE
                # FUNCTION bei PostgreSQL endet das Statement nicht unbedingt
                # mit dem ersten Semikolon am Zeilenende. Ggf. müssen wir
                # den Inhalt zwischen den Begrenzern $STR$ ... $STR$
                # (STR ist ein frei gewählter Bezeichner) überlesen.
                # Die Begrenzer sind aber optional. 

                # Begrenzer ermitteln
                my ($as) = $stmt =~ /AS\s+(\$.*?\$)/i;
                if (!$as) {
                    # Kein Begrenzer, also Ende des Statement
                    last;
                }

                # Anzahl der bereits gelesenen Begrenzer ermitteln

                my $i = 0;
                while ($stmt =~ /\Q$as/g) {
                    $i++;
                }

                # Haben wir erst einen Begrenzer gelesen, müssen wir
                # bis zum zweiten Begrenzer und darüber hinaus bis
                # zum Semikolon lesen.

                if ($i == 1) {
                    my $asFound = 0;
                    while (<$fh>) {
                        $stmt .= $_;
                        if ($asFound && /;\s*$/) {
                            last;
                        }
                        elsif (/\Q$as/) {
                            $asFound = 1;
                        }
                    }
                }
            }
            last;
        }
    }

    if (defined $stmt) {
        $stmt =~ s/^\n+//;    # Leerzeilen am Anfang entfernen
        $stmt =~ s/[;\s]*$//; # Whitespace und Semikolon am Ende entfernen
    }

    return $stmt;
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
