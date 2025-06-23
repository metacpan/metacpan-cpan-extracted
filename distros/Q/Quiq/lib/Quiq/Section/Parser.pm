# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Section::Parser - Parser für Abschnitte

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Parser für "Abschnitte".

=head2 Syntax

Ein Abschnitt hat den Aufbau:

  # [IDENTIFIER]
  
  KEY:
      VALUE
  ...
  
  CONTENT

=over 4

=item IDENTIFIER

Abschnittsbezeichner.

=item KEY

Schlüssel. Ein Abschnitt kann beliebig viele
Schlüssel/Wert-Paare definieren.

=item VALUE

Wert. Ist mit einer bestimmten Tiefe an Whitespace eingerückt.
Kann mehrzeilig sein.

=item CONTENT

Inhalt. Ist typischerweise mehrzeilig. Es kann höchstens
einen Inhalt je Abschnitt geben.

=back

=head1 ATTRIBUTES

=over 4

=item encoding => $charset (Default: undef)

Dekodiere Input gemäß Zeichensatz.

=item sectionRegex => $regex (Default: qr/^# (<\w+>|\[\w+\]|\(\w+\)|\{\w+\})/)

Muster für die erste Zeile eines Abschnitts.

=item defaultSection => $section (Default: undef)

Default für die erste Zeile eines Abschnitts. Diese Option kann
gesetzt werden, wenn eine Datei aus nur einem Abschnitt besteht
und daher keine einleitende Zeile notwendig ist.

=item keyRegex => $regex (Dafault: qr/^(\w+):$/)

Muster für eine Schlüssel-Zeile.

=item sourceNotNeeded => $bool (Default: 0)

Speichere den geparsten Quelltext nicht im Abschnittsobjekt.
Dies spart Speicherplatz, wenn der Quelltext nicht gebraucht wird.

=item startLine => $line (Default: "--BEGIN--\n")

Startzeile für den Inhalt.

=item parsedSections

Anzahl der geparsten Abschnitte. Das Attribut kann nur abgefragt werden.

=item parsedLines

Anzahl der geparsten Zeilen. Das Attribut kann nur abgefragt werden.

=item parsedChars

Anzahl der geparsten Zeichen. Das Attribut kann nur abgefragt werden.

=item parsedBytes

Anzahl der geparsten Bytes. Das Attribut kann nur abgefragt werden.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Section::Parser;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

no bytes;
use Quiq::Section::Object;
use Quiq::FileHandle;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $par = $class->new(@keyVal);

=head4 Returns

Referenz auf Parser-Objekt

=head4 Description

Instantiiere ein Parser-Objekt mit den Parser-Attributen I<@keyVal>.
In abgeleiteten Klassen kann der Konstruktor überschrieben und
eine andere Attribut-Initialisierung vorgenommen werden.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        encoding => undef,
        defaultSection => undef,
        sectionRegex => qr/^# (<\w+>|\[\w+\]|\(\w+\)|\{\w+\})/,
        keyRegex => qr/^(\w+):$/,
        sourceNotNeeded => 0,
        startLine => "--BEGIN--\n",
        parsedSections => 0,
        parsedLines => 0,
        parsedChars => 0,
        parsedBytes => 0,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Parsing

=head3 parse() - Parse Abschnitte

=head4 Synopsis

  $objA|@objs = $par->parse(undef[,$sub]);
  $objA|@objs = $par->parse($file[,$sub]);
  $objA|@objs = $par->parse(\$text[,$sub]);

=head4 Arguments

=over 4

=item $file

Name der Eingabedatei. Ist der Parameter C<undef> oder ein
Leerstring oder '-', wird die Eingabe von STDIN gelesen.

=item \$text

Lies die Eingabe vom String ("In-Memory-File") $text.

=item $sub

Anonyme Callback-Funktion, die nach jedem geparsten Abschnitt
aufgerufen wird. Die Funktion bekommt die geparste Information in
Form einzelner Parameter übergeben, instantiiert ein Objekt und
liefert dieses zurück. Alle Objekte werden von der Methode
parse() gesammelt und am Ende zurückgeliefert. Die Klasse des
Objektes ist nicht festgelegt. Wird kein Objekt geliefert, wird
der Return-Wert von parse() ignoriert.

Ist der Parameter $sub nicht angegeben, wird folgende
Default-Definition genutzt:

  sub {
      # @_: $type,$keyValH,$keyA,$content,$source,$file,$lineNumber
      return Quiq::Section::Object->new(@_);
  }

=back

=head4 Returns

Liste der Abschnittsobjekte (Array-Kontext) oder Referenz auf
die Liste (Skalar-Kontext).

=head4 Description

Parse die Eingabe und liefere die Liste der Abschnittsobjekte zurück.
Die Eingabe besteht aus einer Folge von 0 bis n
L<Syntax|"Syntax">. Die Methode kann wiederholt mit
verschiedenen Eingaben aufgerufen werden.

=cut

# -----------------------------------------------------------------------------

sub parse {
    my $self = shift;
    my $input = shift || '-';
    my $sub = shift || sub {
        # @_: $type,$keyValH,$keyA,$content,$source,$file,$lineNumber
        return Quiq::Section::Object->new(@_);
    };
    
    # Parser-Eigenschaften

    my $encoding = $self->{'encoding'};
    my $defaultSection = $self->{'defaultSection'};
    my $sectionRegex = $self->{'sectionRegex'};
    my $keyRegex = $self->{'keyRegex'};
    my $sourceNotNeeded = $self->{'sourceNotNeeded'};
    my $indRegex; # Einrückungs-Regex (wird erzeugt)
    my $startLine = $self->{'startLine'};
    my $stopLine; # Wird je Abschnitt über Stop: gesetzt

    # Zustandsvariablen

    my $state = 0;         # aktueller Parser-Zustand
    my $key;               # aktueller Schlüssel
    my $val = '';          # akuteller Schlüsselwert
    my $stop;              # ignoriere weiteren Content

    # Lokale Variablen

    my $identifier;        # Abschnitts-Identifier (initiale Zuweisung)
    my $keyA;              # Array der Schlüssel (wird aufgebaut)
    my $keyValH;           # Hash der Schlüssel/Wert-Paare (wird aufgebaut)
    my $content;           # Inhalt (wird aufgebaut)
    my $source = '';       # Quelltext (wird aufgebaut)
    my $file = ref $input? '(source)': $input; # über parse()-Aufruf konstant
    my $lineNumber;        # Zeilennummer (initiale Zuweisung)

    # Objektliste
    my $objA = [];

    # Hilfsfunktionen

    my $processAttribute = sub {
        if (!$indRegex) {
            # Einrückung bei erstem Attribut
            # für die gesamte Eingabe ermitteln

            my ($indentation) = $val =~ /^(\s*)/;
            $indRegex = qr/^$indentation/m;
        }

        $val =~ s/$indRegex//g;   # Einrückung entfernen
        $val =~ s/\s+$//;         # WS am Ende entfernen
        $val =~ s/\s+\!\!\s.*//g; # eingebettete Kommentare entfernen

        # Schlüssel/Wert-Paar

        if ($key eq 'Stop') {
            $stopLine = "$val\n";
        }
        else {
            # Schlüssel-Array und Schlüssel/Wert-Hash aufbauen
            my $scal = $keyValH->{$key};
            if (ref $scal) {
                push @$scal,$val;
            }
            elsif (defined $scal) {
                $keyValH->{$key} = [$scal,$val];
            }
            else {
                $keyValH->{$key} = $val;
                push @$keyA,$key;
            }
        }
    };

    my $processContent = sub {
        if (!$stopLine) {
            $content =~ s/\n+$//; # Newlines am Ende entfernen
        }
    };

    my $processSection = sub {
        $self->{'parsedSections'}++;
        $self->{'parsedChars'} += length $source;
        $self->{'parsedBytes'} += bytes::length($source);
        if ($sourceNotNeeded) {
            $source = '';
        }
        my $obj = $sub->($identifier,$keyValH,$keyA,$content,
            $source,$file,$lineNumber);
        if ($obj) {
            push @$objA,$obj;
        }
    };

    # Zeilen-Parsing

    my $fh = Quiq::FileHandle->new('<',$input);
    if ($encoding) {
        $fh->binmode(":encoding($encoding)");
    }
    my $line = 1;
    eval {
        while (<$fh>) {
            if ($state == 0) {
                if (/$sectionRegex/ || $defaultSection) {
                    my $isDefaultSection = $1? 0: 1;
                    my $nextIdentifier = $1 || $defaultSection;
    
                    if ($source) {
                        # Abschnitt verarbeiten
                        $processSection->();
                    }

                    # Start neuer Abschnitt (Objektvariablen initialisieren)

                    $identifier = $nextIdentifier;
                    $keyA = [];
                    $keyValH = Quiq::Hash->new->unlockKeys;
                    $content = $source = '';
                    $lineNumber = $line;

                    # Stop-Zeile gilt je Abschnitt

                    $stop = 0;
                    $stopLine = undef;

                    # nächster Zustand
                    $state = 1;

                    if ($isDefaultSection) {
                        # Erste Zeile, die kein Abschnitts-Bezeichner
                        # ist, noch einmal verarbeiten
                        redo;
                    }
                }
                else {
                    # Syntaxfehler
                    die 'SECPAR-00001: Abschnitt erwartet',"\n";
                }
            }
            elsif ($state == 1) {
                if (/^\s*$/) {
                    # Leerzeilen am Abschnittsanfang überlesen
                }
                else {
                    # Schlüssel/Wert-Folge oder Beginn Inhalt
                    $state = /$keyRegex/? 2: 3;
                    redo;
                }
            }
            elsif ($state == 2) {
                if (/^\s*\!\! /) {
                    # vollständig auskommentierte Zeilen übergehen
                }
                elsif (/$keyRegex/ || /^\S/) {
                    my $nextKey = $1;

                    # Attribut/Wert-Paar verarbeiten

                    if ($key) {
                        # Attribut-Event generieren
                        $processAttribute->();
                    }

                    # nächstes Attribut/Wert-Paar

                    $key = $nextKey;
                    $val = '';

                    if (!$key) {
                        # letztes Schlüssel/Wert-Paar via ^\S erreicht

                        if ($_ eq $startLine) {
                            # Beginn Inhalt (Zeile überlesen, kein redo)
                            $state = 3;
                        }
                        elsif (/^# ---+/) {
                            # Beginn Inhalt (Zeile überlesen, kein redo)

                            $state = 3;
                            $source .= $_;
                            $line++;

                            # Nächste Zeile prüfen. Wenn leer, überlesen.

                            $_ = <$fh>;
                            if (!/^\s*$/) {
                                redo; # Zeile als Content-Zeile verarbeiten
                            }
                        }
                        else {
                            # sonstige Zeile
                            $state = /$sectionRegex/? 0: 3;
                            redo;
                        }
                    }
                }
                else {
                    if ($indRegex && $_ ne "\n" && !/$indRegex/) {
                        my $str = $_;
                        chomp $str;
                        warn sprintf 'WARNING: Unerwartete Einrückung'.
                            qq| (%s:%d): "%s"\n|,$file,$line,$str;
                    }

                    # Wertzeile
                    $val .= $_;
                }
            }
            elsif ($state == 3) {
                if (/$sectionRegex/ && (!$stopLine || $stop)) {
                    # Inhalt verarbeiten
                    $processContent->();
                    $state = 0;
                    redo;
                }
                else {
                    if ($stopLine && $_ eq $stopLine) {
                        # Wenn Stop-Zeile definiert und erreicht ist, alle
                        # Zeilen bis zum nächsten Abschnittsanfang ignorieren
                        $stop = 1;
                    }
                    if (!$stop) {
                        $content .= $_;
                    }
                }
            }
            else {
                # Paranoia
                die 'SECPAR-00002: Unerwarteter Zustand',"\n";
            }
            $source .= $_;
            $line++;
        }
        if ($state == 2) {
            if ($key) {
                # Attribut/Wert-Paar verarbeiten
                $processAttribute->();
            }
        }
        elsif ($state == 3) {
            if ($content) {
                # Inhalt verarbeiten
                $processContent->();
            }
        }
        if ($source) {
            # Abschnitt verarbeiten
            $processSection->();
        }
    };
    if ($fh != \*STDIN) { # STDIN schließen wir nicht
        $fh->close;
    }
    # $self->{'parsedSections'} += @$objA;
    $self->{'parsedLines'} += $line-1;

    if ($@) {
        $self->error($@,"$source$_",$file,$line);
    }

    return wantarray? @$objA: $objA;
}

# -----------------------------------------------------------------------------

=head2 Events

=head3 section() - Verarbeite Abschnitt

=head4 Synopsis

  $obj = $par->section($identifier,$keyValH,$keyA,$content,$source,$file,$lineNumber);

=head4 Arguments

=over 4

=item $identifier

Abschnitts-Bezeichner einschließlich Klammern.

=item $keyValH

Referenz auf Schlüssel/Wert-Hash.

=item $keyA

Referenz auf Schlüssel-Array.

=item $content

Der Inhalt.

=item $source

Der Quelltext des Abschnitts.

=item $file

Der Name der Datei, die den Abschnitt enthält. Im Falle einer
In-Memory-Datei "C<(source)>".

=item $lineNumber

Die Zeilennummer, an der der Abschnitt in der Datei beginnt.

=back

=head4 Returns

Nichts oder Abschnitts-Objekt

=head4 Description

Die Methode wird vom Parser für jeden vollständig geparsten Abschnitt
gerufen.

=head4 Details

Die Methode instantiiert per Default ein Objekt der Klasse
C<< Quiq::Section::Object >> und liefert eine Referenz auf dieses Objekt
zurück. Das Objekt wird zur Liste der Abschnittsobjekte hinzugefügt.
Die Liste der Abschnittsobjekte wird von der Methode L<parse|"parse() - Parse Abschnitte">()
zurückgeliefert. In abgeleiteten Klassen kann die Methode überschrieben
und ein anderes Verhalten implementiert werden.

=cut

# -----------------------------------------------------------------------------

sub section {
    my $self = shift;
    # @_: $identifier,$keyValH,$keyA,$content,$source,$file,$lineNumber
    return Quiq::Section::Object->new(@_);
}

# -----------------------------------------------------------------------------

=head3 error() - Behandele Fehler

=head4 Synopsis

  $par->error($@,$source,$file,$lineNumber);

=head4 Arguments

=over 4

=item $@

Die Exception.

=item $source

Der Quelltext des Abschnitts bis zur Exception.

=item $file

Der Name der Datei, die den Abschnitt enthält. "C<(source)>" im Falle
einer In-Memory-Datei.

=item $lineNumber

Die Zeilennummer, bei der die Exception ausgelöst wurde.

=back

=head4 Returns

Die Methode kehrt nicht zurück

=head4 Description

Die Methode wird vom Parser im Fehlerfall gerufen.

=head4 Details

Die Methode empfängt die betreffende Exception und erzeugt eine neue
Exception, die um Angaben zur Fehlerstelle angereichert ist.
In abgeleiteten Klassen kann die Methode überschrieben und ein
anderes Verhalten implementiert werden.

=cut

# -----------------------------------------------------------------------------

sub error {
    my ($self,$msg,$source,$file,$lineNumber) = @_;

    $self->throw($msg,
        # Source => $source,
        $msg !~ /^File:/m? (File=>$file): (),
        $msg !~ /^Line:/m? (Line=>$lineNumber): (),
        -stacktrace => 0,
    );
}

# -----------------------------------------------------------------------------

=head1 DETAILS

=head2 Klammerung IDENTIFIER

Anstelle der eckigen Klammern C<[]> kann der Abschnittsbezeichner
I<IDENTIFIER> per Default auch in spitze C<< <> >>, runde C<()> oder
geschweifte Klammern {} eingefasst sein. Das Muster kann durch
Überschreiben des Parser-Attributs C<< sectionRegex=> >>I<$regex>
geändert werden.

=head2 Einrücktiefe VALUE

Die Einrücktiefe der I<VALUE>-Zeilen ermittelt der Parser anhand
der ersten Zeile des ersten Schlüssel/Wert-Paars der Datei. Alle
weiteren Werte in der Datei müssen in der gleichen Tiefe
eingerückt sein.

=head2 KEY-Zeile auskommentieren

I<KEY>-Zeilen können auskommentiert werden, indem zwei
Ausrufungszeichen I<!!> gefolgt von mindestens einem Leerzeichen
an den Anfang der Zeile gesetzt werden. Einschränkung: Die erste
I<KEY>-Zeile kann nicht auskommentiert werden, da sie den
betreffenden I<KEY/VALUE>-Abschnitt einleitet.  Beispiel
(dargestellt mit Pipe- statt Ausrufungszeichen):

  Name:
      width
  
  || BriefDescription:
  ||     Liefere die Breite und Höhe des Bildes

Ergebnis:

  Name:
      width

=head2 VALUE auskommentieren

I<VALUE>-Zeilen können ganz oder teilweise auskommentiert werden.
Eine ganze I<VALUE>-Zeile wird wie eine I<KEY>-Zeile auskommentiert (s.o.).
Ein Teil wird auskommentiert, indem mindestens ein Leerzeichen
gefolgt von zwei Ausrufungszeichen gefolgt von einem Leerzeichen in eine
I<VALUE>-Zeile eingefügt wird. Ab dem ersten Leerzeichen werden bis
zum Ende der Zeile alle Zeichen ignoriert. Beispiel (mit Pipe-
statt Ausrufungszeichen):

  Imports:
      || Old::Hash
      New::Hash || neue Hash-Klasse

Ergebnis:

  Imports:
      New::Hash

=head2 Start-Zeichenkette CONTENT

Beginnt I<CONTENT> mit einer Zeile, die wie eine I<KEY>:-Zeile
aussieht, oder sind Leerzeilen am Anfang von I<CONTENT>
signifikant, muss der Anfang von I<CONTENT> mit einer
Start-Zeichenkette gekennzeichnet werden. Die Start-Zeichenkette
ist C<--BEGIN--> oder C<# ---> mit drei oder mehr Bindestrichen
bis zum Ende der Zeile. Folgt auf eine C<# --->-Zeile eine Leerzeile,
wird diese übergangen, also nicht zum Inhalt hinzugezählt. Dies ist
bei C<--BEGIN--> nicht der Fall.

=head2 Stop-Zeichenkette CONTENT

Enthält I<CONTENT> eine Zeile, die wie der Anfang eines Abschnitts
aussieht (welcher I<CONTENT> per Default beendet) oder sind Leerzeilen
am Ende von I<CONTENT> signifikant, muss dessen Ende mit einer
Stop-Zeichenkette gekennzeichnet werden. Sie Stop-Zeichenkette
wird durch Schlüssel/Wert-Paar C<Stop:> definiert:

  Stop:
      --END--

C<Stop:> ist eine Parser-Direktive, die nur für den Abschnitt gilt, in
dem sie definiert ist. Die Stop-Zeichenkette beendet I<CONTENT> und
zählt nicht zum I<CONTENT> hinzu.

=head2 Datei mit einem einzelnen Abschnitt

Besteht eine Datei aus einem einzelnen Abschnitt, kann die
Abschnitts-Einleitungszeile

  # IDENTIFIER

weggelassen werden, wenn IDENTIFIER (mit Klammerung)
als Default-Section definiert wird:

  $par = Quiq::Section::Parser->new(
      defaultSection => $identifier,
      ...
  );

Als Beispiel siehe quiq-confluence:

  my $par = Quiq::Section::Parser->new(
      defaultSection => '[ConfluencePage]',
  );
  my ($sec) = $par->parse($file);

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
