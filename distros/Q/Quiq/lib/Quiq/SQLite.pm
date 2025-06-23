# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::SQLite - Operationen auf einer SQLite-Datenbank

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::SQLite;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Database::Connection;
use Quiq::Path;
use Quiq::Terminal;
use POSIX ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 exportData() - Exportiere SQLite Tabellendaten in Verzeichnis

=head4 Synopsis

  $class->exportData($dbFile,$exportDir);

=head4 Arguments

=over 4

=item $dbFile

SQLite Datenbank-Datei.

=item $exportDir

Verzeichnis, in das die Tabellendaten exportiert werden.

=back

=head4 Description

Exportiere die Tabellendaten der SQLite-Datenbank $dbFile in
Verzeichnis $exportDir.

=head4 Example

  Quiq::SQLite->exportData('~/var/myapp/myapp.db','/tmp/myapp');

=cut

# -----------------------------------------------------------------------------

sub exportData {
    my ($class,$dbFile,$exportDir) = @_;

    # Exportiere die Tabellendaten

    my $udl = "dbi#sqlite:$dbFile";
    my $db = Quiq::Database::Connection->new($udl,-utf8=>1);

    my @tables = $db->values(
        -select => 'name',
        -from => 'sqlite_master',
        -where,
            type => 'table',
            "tbl_name NOT LIKE 'sqlite_%'",
        -orderBy => 'name',
    );

    for my $table (@tables) {
        $db->exportTable($table,"$exportDir/$table.dat");
    }

    $db->disconnect;

    return;
}

# -----------------------------------------------------------------------------

=head3 importData() - Importiere SQLite Datenbank aus Verzeichnis

=head4 Synopsis

  $class->importData($dbFile,$importDir);

=head4 Arguments

=over 4

=item $dbFile

SQLite Datenbank-Datei.

=item $exportDir

Verzeichnis, aus dem die Tabellendaten importiert werden.

=back

=head4 Description

Importiere die Tabellendaten der SQLite-Datenbank $dbFile aus
Verzeichnis $importDir.

=head4 Example

  Quiq::SQLite->importData('~/var/myapp/myapp.db','/tmp/myapp');

=cut

# -----------------------------------------------------------------------------

sub importData {
    my ($class,$dbFile,$importDir) = @_;

    # Importiere Tabellendaten

    my $udl = "dbi#sqlite:$dbFile";
    my $db = Quiq::Database::Connection->new($udl,-utf8=>1);
    $db->sql('PRAGMA foreign_keys = OFF');

    for my $file (Quiq::Path->glob("$importDir/*.dat")) {
        my ($table) = $file =~ m|/([^/]+).dat$|;
        $db->delete($table);
        $db->importTable($table,$file);
    }
    $db->disconnect(1);

    return;
}

# -----------------------------------------------------------------------------

=head3 recreateDatabase() - Erzeuge SQLite Datenbank neu

=head4 Synopsis

  $class->recreateDatabase($dbFile,$exportDir,@opt,$sub);

=head4 Arguments

=over 4

=item $dbFile

SQLite Datenbank-Datei.

=item $exportDir

Verzeichnis, in das die Tabellendaten und Datenbank-Datei gesichert
werden. Schlägt die Neuerzeugung fehl, müssen die Tabellendaten
eventuell bearbeitet und die Neuerzeugung wiederholt werden.
Die ursprüngliche Datenbank kann bei Bedarf wieder hergestellt
werden, da sie zuvor ebenfalls in das Exportverzeichnis gesichert
wurde (s.u.).

=item $sub

Refenz auf die Subroutine, die das Schema auf einer I<leeren>
Datenbank erzeugt. Als einzigen Parameter wird $dbFile
an die Subroutine übergeben.

  $class->recreateDatabase('~/var/myapp/myapp.db','/tmp/myapp',sub {
      my $dbFile = shift;
  
      my $db = %<Quiq::Database::Connection->new("dbi#sqlite:$dbFile",
          -utf8 => 1,
      );
  
      # via $db alle Schemaobjekte erzeugen,
      # aber keine Daten importieren!
      ...
  
      return;
  });

=back

=head4 Options

=over 4

=item -interactive => $bool (Default: 1)

Stelle Rückfragen an den Benutzer.

=back

=head4 Description

Erzeuge die Datenbank $dbFile via Subroutine $sub erstmalig oder neu.
Dies erfolgt in folgenden Schritten:

=over 4

=item 1.

Tabellendaten in Exportverzeichnis exportieren

=item 2.

Datenbank $dbFile in Exportverzeichnis kopieren (sichern)

=item 3.

Datenbank $dbFile leeren

=item 4.

Datenbank-Strukturen via $sub erzeugen

=item 5.

die unter 2. exportierten Daten importieren

=item 6.

Exportverzeichnis löschen (falls in den Schritten 4. bis 6.
kein Fehler aufgetreten ist)

=back

Die Schritte 1. und 2. finden nur nach Rückfrage statt, wenn
das Exportverzeichnis bereits existiert. Das Exportverzeichnis existiert
typischerweise nur, wenn ein vorheriger Neuerzeugungsversuch
fehlgeschlagen ist.

=cut

# -----------------------------------------------------------------------------

sub recreateDatabase {
    my $class = shift;
    # @_: $dbFile,$exportDir,@opt,$sub

    # Optionen und Argumente

    my $interactive = 1;

    my $argA = $class->parameters(3,3,\@_,
        -interactive => \$interactive,
    );
    my ($dbFile,$exportDir,$sub) = @$argA;

    # Operation ausführen

    my $p = Quiq::Path->new;

    # Exportiere Tabellendaten und sichere Datenbank. Wenn das
    # Exportverzeichnis bereits existiert, stellen wir eine
    # Rückfrage, denn es könnte der erneute Versuch nach einem
    # fehlgeschlagenen Import sein.

    my $export = 1;
    if ($p->exists($exportDir) && $interactive) {
        my $answ = Quiq::Terminal->askUser(
            "ExportDir $exportDir already exists. Delete and export again?",
            -values => 'y/n',
            -default => 'n',
        );
        if ($answ eq 'n') {
            $export = 0;
        }
    }
    else {
        say "Creating exportdir $exportDir ...";
        $p->mkdir($exportDir,-recursive=>1);
    }

    if ($export) {
        if ($interactive) {
            say "Exporting table data to $exportDir ...";
        }
        $class->exportData($dbFile,$exportDir);

        my $saveDir = '~/tmp';
        $p->mkdir($saveDir,-recursive=>1);
        my (undef,undef,$basename,$ext) = $p->split($dbFile);
        my $now = POSIX::strftime('%Y%m%d-%H%M%S',localtime);
        my $destFile = sprintf '%s/%s-%s.%s',$saveDir,$basename,$now,$ext;
        if ($interactive) {
            say "Saving database $dbFile to $destFile ...";
        }
        $p->copy($dbFile,$destFile,-preserve=>1);
    }

    # Erzeuge Datenbank neu und importiere Tabellendaten

    my $status = eval {
        if ($interactive) {
            say "Truncating database $dbFile ...";
        }
        $p->truncate($dbFile);
        if ($interactive) {
            say "Creating tables etc. ...";
        }
        $sub->($dbFile);
        my $answ = Quiq::Terminal->askUser(
            "Ready to import data from $exportDir?",
            -values => '(y)es,(a)bort',
            -default => 'y',
            -automatic => !$interactive,
        );
        if ($answ eq 'y') {
            if ($interactive) {
                say "Importing table data from $exportDir ...";
            }
            $class->importData($dbFile,$exportDir);
        }
        return $answ;
    };
    if ($@) {
        $class->throw(
             'SQLITE-00001: Recreation of database failed',
             Database => $dbFile,
             ExportDir => $exportDir,
             Error => $@,
        );
    }
    if ($status eq 'y') {
        # Wenn alles geklappt hat, löschen wir das Exportverzeichnis

        if ($interactive) {
            say "Deleting $exportDir ...";
        }
        $p->delete($exportDir);
    }

    return;
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
