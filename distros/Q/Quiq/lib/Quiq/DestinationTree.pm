# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::DestinationTree - Verwalte Zielbaum eines Datei-Generators

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

  use Quiq::DestinationTree;
  
  $dt = Quiq::DestinationTree->(@dirs);
  ...
  # Dateien und Verzeichnisse erzeugen
  $dt->addFile($file,$content);
  $dt->addDir($dir);
  ...
  # Überzählige Dateien und Verzeichnisse entfernen
  $dt->cleanup;

=head1 DESCRIPTION

Die Klasse verwaltet die Dateien und Unterverzeichnisse von
einem oder mehreren Zielverzeichnissen. Sie ist für Dateigeneratoren
gedacht, die den Inhalt ihrer Zielverzeichnisse komplett
kontrollieren.

=cut

# -----------------------------------------------------------------------------

package Quiq::DestinationTree;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Quiq::Option;
use Quiq::DirHandle;
use Quiq::Path;
use Quiq::Terminal;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $tree = $class->new(@dirs,@opt);

=head4 Options

=over 4

=item -cleanup => $bool (Default: 0)

Entferne alle Dateien und Verzeichnisse, die generiert wurden.

Diese Option ist für ein "make clean" nützlich. Im Unterschied
zu einem $tree->cleanup() direkt nach Objektinstantiierung,
werden hierbei Dateien, die mit -writeInitially=>1 erzeugt wurden,
nur dann gelöscht, wenn sie nicht modifiziert wurden. Wurden
sie modifiziert, bleiben sie erhalten.

=item -dryRun => $bool (Default: 0)

Ändere nichts, zeige die Operationen nur an.

=item -exclude => $regex (Default: keiner)

Schließe alle Dateien, die Regex $regex erfüllen von der Betrachtung
aus. D.h. diese werden vom Nutzer der Klasse nicht verwaltet (weder
erzeugt noch entfernt).

=item -files => \@files (Default: [])

Liste von Einzeldateien. Beispiel:

  -files=>[glob '*_1.sql'],

=item -force => $bool (Default: 0)

Forciere das Schreiben aller Dateien, auch wenn ihr Inhalt nicht
differiert.

=item -include => $regex (Default: keiner)

Berücksichtige nur Dateien, die Regex $regex erfüllen, alle anderen
werden von der Klasse nicht verwaltet (weder erzeugt noch entfernt).

=item -inHandle => $fh (Default: \*STDIN)

Filehandle, von der Benutzereingaben gelesen werden.

=item -language => 'de'|'en' (Default: 'de')

Sprache für die Kommunikation mit dem Benutzer.

=item -prefix => $str (Default: '')

Setze Zeichenkette $str an den Anfang jeder Änderungsmeldung.
Beispiel: C<< -prefix=>'* ' >>

=item -quiet => $bool (Default: 0)

Schreibe keine Meldungen nach STDERR.

=item -outHandle => $fh (Default: \*STDOUT)

Filehandle, auf die Ausgaben geschrieben werden.

=back

=head4 Description

Instantiiere ein Dateibaumobjekt über den Verzeichnissen @dirs
und liefere eine Referenz auf dieses Objekt zurück. Die Verzeichnisse
in @dirs müssen nicht existieren. Hat ein Verzeichnis die Form
"DIR/*" wird nicht rekursiv in DIR abgestiegen, sondern nur
die Dateien (nicht die Verzeichnisse) in DIR werden verwaltet.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @dirs,@opt

    my $cleanup = 0;
    my $dryRun = 0;
    my $exclude = undef;
    my $files = [];
    my $force = 0;
    my $include = undef;
    my $inHandle = \*STDIN;
    my $language = 'de';
    my $outHandle = \*STDOUT;
    my $prefix = '';
    my $quiet = 0;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -cleanup => \$cleanup,
        -dryRun => \$dryRun,
        -exclude => \$exclude,
        -files => \$files,
        -force => \$force,
        -include => \$include,
        -inHandle => \$inHandle,
        -language => \$language,
        -outHandle => \$outHandle,
        -prefix => \$prefix,
        -quiet => \$quiet,
    );

    my %path;
    for my $dir (@_) {
        next if defined $dir && $dir ne '' && !-e $dir;

        if ((my $dir) = $dir =~ m|(.*)/\*$|) {
            # Füge nur die Dateien aus dem Verzeichnis hinzu, steige
            # nicht in Subverzeichnisse ab
            
            my $dh = Quiq::DirHandle->new($dir);
            while (my $path = $dh->next) {
                $path = "$dir/$path";
                next if !-f $path; # wir verwalten nur die Dateien
                next if $exclude && $path =~ /$exclude/;
                next if $include && $path !~ /$include/;
                $path{$path} = 1;
            }
            $dh->close;

            next;
        }

        # Rekursiver Abstieg

        for (Quiq::Path->find($dir,
            -exclude => $exclude,
        )) {
            s|^\./||; # ./ am Pfadanfang entfernen

            next if $_ eq '';
            # next if $exclude && /$exclude/; # hier ignorieren wir Dateien

            # füge Verzeichnisse immer hinzu, wenn sie nicht excluded wurden

            if (-d) {
                $path{$_} = 1;
                next;
            }

            next if $include && !/$include/;

            $path{$_} = 1;

        }
    }

    # Einzeldateien
    @path{@$files} = (1) x @$files;

    return bless [
        \%path,     # [0]
        $force,     # [1]
        $quiet,     # [2]
        $cleanup,   # [3]
        $inHandle,  # [4]
        $outHandle, # [5]
        $language,  # [6]
        $prefix,    # [7]
        $dryRun,    # [8]
    ],$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 addDir() - Füge Verzeichnis zum Dateibaum hinzu

=head4 Synopsis

  $bool = $tree->addDir($dir);

=head4 Description

Füge Verzeichnis $dir zum Dateibaum hinzu. Die Methode liefert 1, wenn
das Verzeichnis effektiv erzeugt wurde (s.u.)  oder 0, wenn dies nicht
der Fall war.

Das Verzeichnis wird effektiv nur erzeugt, wenn es noch nicht
existiert. In dem Fall schreibt die Methode eine entsprechende Meldung
auf den Ausgabekanal und liefert als Returnwert 1.

Der Rückgabewert kann benutzt werden, um im Falle der
Verzeichniserzeugung weitere Aktionen auszuführen, wie z.B. das Setzen
von Verzeichnisrechten.

=cut

# -----------------------------------------------------------------------------

sub addDir {
    my $self = shift;
    my $dir = shift;

    # Nulloperation, wenn Konstruktor-Option -cleanup
    return 0 if $self->[3];

    # Nulloperation, wenn kein Pfad angegeben
    return if !$dir;

    # ./ am Pfadanfang entfernen
    $dir =~ s|^\./||;

    # Eintrag entfernen
    delete $self->[0]{$dir};

    # Vaterverzeichnis hinzufügen, falls vorhanden

    my ($parent) = $dir =~ m|(.*)/|;
    $self->addDir($parent) if $parent;

    # Verzeichnis erzeugen, wenn es nicht existiert

    if (!-e $dir) {
        if (!$self->[8]) {
            Quiq::Path->mkdir($dir);
        }
        if (!$self->[2]) {
            my $out = $self->[5];
            my $msg = $self->getText('Verzeichnis erzeugt');
            print $out "$self->[7]$dir -- $msg\n";
        }
        return 1;
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head3 paths() - Liefere die Liste der Pfade

=head4 Synopsis

  @paths | $pathA = $tree->paths;

=head4 Description

Liefere die Liste der Pfade, die zu den Zielverzeichnissen gehören.

=over 2

=item *

Die Reihenfolge ist undefiniert.

=item *

Die Liste enthält sowohl Verzeichnisse also auch Dateien.

=back

Sortierung herstellen:

  @paths = sort $tree->paths;

Nur Dateien erhalten:

  @paths = grep {!-d} $tree->paths;

=cut

# -----------------------------------------------------------------------------

sub paths {
    my $self = shift;
    my @paths = keys %{$self->[0]};
    return wantarray? @paths: \@paths;
}

# -----------------------------------------------------------------------------

=head3 addFile() - Füge Datei zum Dateibaum hinzu

=head4 Synopsis

  $bool = $tree->addFile($file,$data,@opt);
  $bool = $tree->addFile($file,\$data,@opt);
  $bool = $tree->addFile($file,@opt);
  $bool = $tree->addFile($file,
      -generate => $bool,
      -onGenerate => sub {
          ...
          return $data;
      },
      @opt
  );

=head4 Options

=over 4

=item -encoding => $encoding (Default: undef)

Encodiere/decodiere die Daten mit Encoding $encoding.

=item -force => $bool (Default: 0)

Forciere das Schreiben der Datei ohne den Dateiinhalt zu vergleichen.
Die Option ist nützlich, wenn der Aufrufer bereits festgestellt hat,
dass eine Differenz besteht.

=item -generate => $bool (Default: 0)

Rufe die onGenerate-Subroutine auf, um den Dateiinhalt zu generieren.

=item -onGenerate => sub { ... } (Default: undef)

Die Subroutine generiert und liefert den Inhalt der Datei. Sie wird
aufgerufen, wenn Argument $data nicht definiert ist und die Datei
nicht existiert oder Option -generate I<wahr> ist.

=item -onUpdate => sub { ... } (Default: undef)

Führe Subroutine aus, I<bevor> Datei $file geschrieben wird.

=item -quiet => $bool (Default: 0)

Unterdrücke Ausgabe der Meldung.

=item -skipEmptyFiles => $bool

Übergehe Dateien mit leerem Inhalt.

=item -writeInitially => $bool (Default: 0)

Schreibe Datei nur, wenn sie nicht existiert.

Diese Option ist nützlich, wenn von einer Datei ein anfängliches
Muster erzeugt werden soll, das anschließend manuell bearbeitet werden
kann. Die manuell bearbeitete Datei soll danach natürlich nicht mehr
vom Muster überschieben werden.

=back

=head4 Description

Füge Datei $file mit dem Inhalt $data zum Dateibaum hinzu. Die
Methode liefert 0, wenn die Datei nicht geschrieben wurde,
1, wenn die Datei existiert hat und geschrieben wurde, 2, wenn
die Datei neu erzeugt wurde.

Ist $data C<undef> wird die Datei nicht geschrieben, bleibt
aber weiter bestehen. Dies ist nützlich, wenn es teuer ist, den Inhalt
der Datei zu generieren, und bekannt ist, dass sich am Inhalt nichts
geändert hat.

Die Datei wird effektiv geschrieben, wenn sie nicht existiert oder der
Inhalt differiert. In dem Fall schreibt die Methode eine entsprechende
Meldung nach STDERR und liefert als Returnwert 1.

Der Rückgabewert kann benutzt werden, um im Falle des Schreibens
der Datei weitere Aktionen auszuführen, wie z.B. das Setzen von
Dateirechten.

=cut

# -----------------------------------------------------------------------------

sub addFile {
    my $self = shift;
    my $file = shift;
    my $dataR = @_%2? (ref $_[0]? shift: \shift): undef;

    my $encoding = undef;
    my $force = 0;
    my $generate = 0;
    my $onGenerate = undef;
    my $onUpdate = undef;
    my $quiet = 0;
    my $skipEmptyFiles = 0;
    my $writeInitially = 0;

    Quiq::Option->extract(\@_, # ehedem: -mode=>'strict-dash'
        -encoding => \$encoding,
        -force => \$force,
        -generate => \$generate,
        -onGenerate => \$onGenerate,
        -onUpdate => \$onUpdate,
        -quiet => \$quiet,
        -skipEmptyFiles => \$skipEmptyFiles,
        -writeInitially => \$writeInitially,
    );

    # Wir ignorieren leere Dateien, wenn -skipEmptyFiles=>1

    if ($skipEmptyFiles && (!$dataR || !defined $$dataR || $$dataR eq '')) {
        return 0;
    }

    # ./ am Pfadanfang entfernen
    $file =~ s|^\./||;

    # Verzeichnis ermitteln
    my ($dir) = $file =~ m|(.*)/|;

    # Wir wissen, dass die Datei nicht modifiziert wurde und wollen
    # sie nicht schreiben.

    if (!defined $dataR || !defined $$dataR) {
        if ((!-e $file || $generate) && $onGenerate) {
            # Wir generieren den Inhalt der Datei
            $dataR = \$onGenerate->($file);
        }
        elsif (!-e $file) {
          # Fataler Fehler. Die Datei existiert nicht und wir können
          # ihren Inhalt nicht erzeugen, da wir ihn nicht haben.

            $self->throw(
                'DTREE-00001: Datei existiert nicht. Ohne Inhalt kann sie nicht angelegt werden.',
                File => $file,
            );
        }
        else {
            # Als Dateiinhalt wurde undef übergeben und die Datei existiert.
            # Wir registrieren die Datei als existent und kehren zurück.

            $self->addDir($dir);
            delete $self->[0]{$file};

            return 0;
        }
    }

    # Nulloperation, bei Konstruktor-Option -cleanup=>1. Ist die
    # Option -writeInitially=>1 angegeben, wird die Datei aus
    # der Pfadliste entfernt, wenn sie existiert und nicht identisch ist,
    # d.h. sie wird im Zuge des cleanup *nicht* gelöscht.

    if ($self->[3]) { # cleanup
        if ($writeInitially && -e $file &&
               Quiq::Path->read($file,-decode=>$encoding) ne $$dataR) {
            # Eintrag entfernen, d.h. Datei am Ende *nicht* löschen
            delete $self->[0]{$file};
        }
        return 0;
    }

    # Eintrag entfernen
    delete $self->[0]{$file};

    # Existenz der Datei ermitteln
    my $fileExists = -e $file;

    # Datei nicht schreiben, wenn sie bereits existiert

    if ($writeInitially && $fileExists) {
        $self->addDir($dir);
        return 0;
    }

    # Inhalt vergleichen. Wenn identisch, Datei nicht schreiben.

    if ($self->[1] || $force || !$fileExists) {
        # nichts tun, wir schreiben auf jeden Fall
    }
    else {
        # Datei existiert. Prüfen, ob die Daten differieren.

        if (Quiq::Path->read($file,-decode=>$encoding) eq $$dataR) {
            $self->addDir($dir);
            return 0;
        }
    }

    # Callbackmethode vor dem Schreiben

    if ($onUpdate) {
        $self->$onUpdate($file,$$dataR);
    }

    # Verzeichnis hinzufügen
    $self->addDir($dir);

    # Datei schreiben

    if (!$self->[8]) {
        Quiq::Path->write($file,$$dataR,-encode=>$encoding);
    }
    if (!$self->[2] && !$quiet) {
        my $out = $self->[5];
        my $msg = $self->getText($fileExists? 'Datei aktualisiert':
            'Datei erzeugt');
        print $out "$self->[7]$file -- $msg\n";
    }

    return $fileExists? 1: 2;
}

# -----------------------------------------------------------------------------

=head3 obsoletePaths() - Liste der überzähligen Pfade

=head4 Synopsis

  @arr | $arr = $tree->obsoletePaths;

=head4 Description

Die Pfade werden lexikalisch absteigend sortiert, so dass der
Inhalt eines Verzeichnisses typischerweise vor dem Verzeichnis
kommt. Dies ist aber nicht garantiert, da Punkt "." und Bindestrich
"-" vor dem Verzeichnistrenner "/" kommen.

=cut

# -----------------------------------------------------------------------------

sub obsoletePaths {
    my $self = shift;
    my @arr = sort {$b cmp $a} keys %{$self->[0]};
    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 removePath() - Lösche Datei oder Verzeichnis aus Baum

=head4 Synopsis

  $bool = $tree->removePath($path);

=head4 Description

Lösche Datei oder Verzeichnis $path aus dem Zielbaum. Liefere 1, wenn
die Löschung durchgeführt wurde, andernfalls 0.

Im Falle eines Verzeichnisses wird die Löschung nur durchgeführt, wenn
das Verzeichnis leer ist. Dateien werden grundsätzlich gelöscht.

=cut

# -----------------------------------------------------------------------------

sub removePath {
    my $self = shift;
    my $path = shift;

    my $removed = 0;
    if (-d $path) {
        if (Quiq::Path->isEmpty($path)) {
            if (!$self->[8]) {
                Quiq::Path->delete($path);
            }
            if (!$self->[2]) {
                my $out = $self->[5];
                my $msg = $self->getText('Verzeichnis gelöscht');
                print $out "$self->[7]$path -- $msg\n";
            }
            $removed = 1;
        }
    }
    else {
        if (!$self->[8]) {
            Quiq::Path->delete($path);
        }
        if (!$self->[2]) {
            my $out = $self->[5];
            my $msg = $self->getText('Datei gelöscht');
            print $out "$self->[7]$path -- $msg\n";
        }
        $removed = 1;
    }

    if ($removed) {
        # Eintrag entfernen
        delete $self->[0]{$path};
    }

    return $removed;
}

# -----------------------------------------------------------------------------

=head3 cleanup() - Entferne überzählige Pfade aus dem Zielbaum

=head4 Synopsis

  $n|@paths = $tree->cleanup;
  $n|@paths = $tree->cleanup($ask);
  $n|@paths = $tree->cleanup($ask,\$timer);

=head4 Returns

Anzahl oder Liste der gelöschten Pfade (Skalarkontext/Arraykontext)

=head4 Description

Entferne alle Dateien und Verzeichnisse aus dem Zielbaum, die obsolet
geworden sind, die seit Objekt-Instantiierung also nicht via
$tree->addFile() oder $tree->addDir() angelegt wurden.

Ist der Parameter $ask angegeben und wahr, wird vor der Löschung
eine Rückfrage auf STDERR gestellt, ob die Löschung wirklich erfolgen
soll. Wird diese nicht mit 'y' beantwortet (auf STDIN), findet
kein Löschen statt und die Methode liefert 0.

Ist ferner der Parameter $timer angegeben, wird die Antwortzeit
des Benutzers auf dessen Wert aufaddiert.

=cut

# -----------------------------------------------------------------------------

sub cleanup {
    my ($self,$ask,$timerR) = @_;

    my @obsoletePaths = $self->obsoletePaths;
    if (@obsoletePaths) {
        if ($ask) {
                my $msg = $self->getText('Überzählige Dateien');
                my $prompt = "$msg:\n";
                for my $path (@obsoletePaths) {
                    # Verzeichnisse zeigen wir nicht an
                    if (-f $path) {
                        $prompt .= "$self->[7]$path\n";
                    }
                }
                $prompt .= $self->getText('Löschen?');

                my $answ = Quiq::Terminal->askUser(
                    $prompt,
                    -values => 'y/n',
                    -default => 'y',
                    -inHandle => $self->[4],
                    -outHandle => $self->[5],
                    $timerR? (-timer=>$timerR): (),
                );

                if ($answ ne 'y') {
                    return wantarray? (): 0;
                }
        }
        else {
            # Doch (erstmal) keine Meldung
            #if (!$self->[2]) {
            #    my $out = $self->[5];
            #    my $msg = $self->getText('Aufräumen');
            #    print $out "*$msg*\n";
            #}
        }
    }

    # Die Liste der überzähligen Pfade wird so lange durchlaufen
    # bis keine Änderungen mehr eintritt. Auf diese Weise wird
    # sichergestellt, dass Elternverzeichnisse gelöscht werden, wenn
    # sie leer werden.

    my @paths;
    while (1) {
        my $n = 0;
        for my $path ($self->obsoletePaths) { # Liste ändert sich!
            if ($self->removePath($path)) {
                $n++;
                push @paths,$path;
            }
        }
        # TODO: Warnung, wenn ungelöschte Pfade übrig bleiben?
        last if $n == 0;
    }

    return @paths;
}

# -----------------------------------------------------------------------------

=head3 close() - Schließe Zielbaumvergleich ab

=head4 Synopsis

  $dt->close;

=head4 Description

Schließe Zielbaumvergeleich ab. Nach Aufruf kann die Objektreferenz
nicht mehr verwendet werden. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub close {
    $_[0] = undef;
    return;
}

# -----------------------------------------------------------------------------

=head3 getText() - Liefere Übersetzung

=head4 Synopsis

  $text = $tree->getText($textDe);

=head4 Returns

Übersetzten Text (String)

=head4 Description

Liefere die Übersetzung zum deutschen Text $textDe.

=cut

# -----------------------------------------------------------------------------

my %Text = (
    'Verzeichnis erzeugt' => 'directory created',
    'Datei aktualisiert' => 'file updated',
    'Datei erzeugt' => 'file created',
    'Verzeichnis gelöscht' => 'directory deleted',
    'Datei gelöscht' => 'file deleted',
    'Überzählige Dateien' => 'Obsolete files',
    'Löschen?' => 'Remove?',
    'Aufräumen' => 'cleanup',
);

sub getText {
    my ($self,$textDe) = @_;
    return $self->[6] eq 'de'? $textDe: $Text{$textDe} || $textDe;
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
