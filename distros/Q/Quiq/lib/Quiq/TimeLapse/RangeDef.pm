package Quiq::TimeLapse::RangeDef;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::OrderedHash;
use Quiq::Path;
use Quiq::FileHandle;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TimeLapse::RangeDef - Range-Definitionen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

    # Klasse laden
    use %CLASS;
    
    # Instantiiere Range-Defintions-Objekt
    $trd = Quiq::TimeLapse::RangeDef->new('/my/timelapse/dir');
    
    # Liste der Clip-Bezeichner
    @keys = $trd->clipKeys;
    
    # Hash der Clip-Properties
    $h = $trd->clipProperties;
    
    # Liste der Range-Bezeichner
    @keys = $trd->rangeKeys;
    
    # Bildfolgen-Ausdruck zu einem Clip- oder Range-Bezeichner
    $expr = $trd->expression($key);

=head1 DESCRIPTION

Ein Objekt der Klasse kapselt die Definitionen aus einer
oder mehrerer range.def-Dateien, die sich innerhalb eines
Verzeichnisbaums befinden.

=head2 Syntax

Eine range.def-Datei besteht aus Zeilen folgender Art:

=over 2

=item *

Leerzeile (leer oder nur Whitespace)

=item *

Kommentar-Zeile (# als erstes non-Whitespace-Zeichen)

=item *

Clip-Definitionszeile (beginnt mit "Clip:")

=item *

Range-Definitionszeile (KEY EXPR)

=item *

Range-Fortsetzungszeile (Zeile mit Whitspace am Anfang, gefolgt von
einer Fortsetzung von EXPR)

=back

Leerzeilen und Kommentarzeilen werden überlesen. Ein Kommentar am Ende
einer Zeile wird entfernt.

=head3 Clip-Definition

Eine Clip-Definition hat den Aufbau:

    Clip: KEY PROPERTY=VALUE ...

C<KEY> ist der Name/Bezeichner des Clip. Die Property-Liste
C<PROPERTY=VALUE ...>  ist optional.

=head3 Clip-Properties

Folgende Clip-Properties können vereinbart werden:

=over 4

=item endFrames=N

=back

Dauer des Nachspanns mit dem Ende-Frame in Sekunden. Ein negativer Wert
setzt die (Mindest-)Dauer des Clip fest.

=over 4

=item framerate=N

=back

Anzahl Bilder pro Sekunde.

=over 4

=item pick=N

=back

Nur jedes N-te Bild ist Teil des Clip.

=over 4

=item reverse=BOOL

=back

Die Bildfolge wird umgedreht.

=head3 Range-Definition

Eine Range-Definition besteht aus einem Namen/Bezeichner KEY und
einem Bildfolgen-Ausdruck EXPR. Diese sind durch Whitspace getrennt.
Der Ausdruck EXPR darf sich über mehrere Zeilen erstrecken,
wenn die Folgezeilen mit Whitespace eingeleitet werden.

=head3 Bildfolgen-Ausdruck

Ein Bildfolgen-Ausdruck EXPR besteht aus 0 oder mehr Teilausdrücken, die
mit Whitespace voneinender getrennt sind. Teilausdrücke sind:

    N  .................. Einzelbild N
    N-M ................. Bildnummern-Bereich N bis M
    KEY ................. die Bilder des Clip oder Range KEY
    all ................. sämtliche Bilder des Zeitraffer-Verzeichnisses
    used ................ die Bilder aller Ranges
    unused .............. die Bilder, die zu keinem Range gehören
    junk ................ Bilder von unused, die per {} ausgesondert sind
    duplicate(N,EXPR) ... jedes Bild in EXPR wird N-mal dupliziert
    randomize(N,EXPR) ... zufällige Auswahl von N Bildern aus Vorrat EXPR
    repeat(N,EXPR) ...... Bildfolge EXPR wird N-mal wiederholt
    reverse(EXPR) ....... Bildfolge EXPR wird umgedreht
    {EXPR} .............. die Bilder aus EXPR werden als Junk betrachtet
    [EXPR] .............. Teilsausdruck EXPR wird nicht berücksichtigt

Betrachten wir C<all>, C<used>, C<unused>, C<junk> als Mengen,
also Bildvorräte ohne Berücksichtigung der Reihenfolge, gilt:

=over 2

=item *

C<all> ist die Vereinigung von C<used> und C<unused>

=item *

C<used> und C<unused> sind disjunkt

=item *

C<junk> ist eine Teilmenge von C<unused>

=back

=head1 EXAMPLE

    # Bilder 1 .. 58
    Clip: autofahrt framerate=8
    strecke1 1-23 {24-30}
    strecke2 31-58

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Range-Definitions-Objekt

=head4 Synopsis

    $trd = $class->new($dir);

=head4 Arguments

=over 4

=item $dir

Pfad zu Verzeichnisstruktur

=back

=head4 Returns

Referenz auf das Range-Definitions-Objekt oder C<undef>

=head4 Description

Instantiiere ein Range-Definitions-Objekt aus den range.def-Dateien in
der Verzeichnisstruktur $dir und liefere eine Referenz auf dieses
Objekt zurück. Existiert keine range.def Datei, wird I<kein> Objekt
instantiiert und C<undef> geliefert.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dir) = @_;

    # Wir speichern die Range- und Clip-Definitionen in geordneten Hashes
    # und die ausgeklammerten Ranges in einem Array.
    
    my $clipH = Quiq::OrderedHash->new;
    my $clipPropertyH = Quiq::OrderedHash->new;
    my $rangeH = Quiq::OrderedHash->new;
    my $junkExpr;
   
    # Range-Definitionsdateien einlesen.

    my @files = sort Quiq::Path->find($dir,-pattern=>qr/range.def$/);
    for my $file (@files) {
        my $clip; # aktueller Clip (für Range-Aufzählung)
        my $range; # aktueller Range (für Fortsetzungszeilen)
        my $fh = Quiq::FileHandle->new('<',$file);
        while (<$fh>) {
            chomp;

            # Kommentar entfernen
            s/\s*#.*//;

            if (/^\s*$/) {
                # Leerzeile
            }
            elsif (/^Clip: (.+)/) {
                # Clip-Definitionszeile
                ($clip,my $prop) = split /\s+/,$1,2;
                if ($clip eq 'null') {
                    $clip = undef;
                    next;
                }

                if ($clipH->exists($clip) || $rangeH->exists($clip)) {
                    $class->throw(
                        'TIMELAPSE-00003: Duplicate clip/range key',
                        Key => $clip,
                        File => $file,
                    );
                }

                # Clip-Eintrag definieren
                $clipH->set($clip=>'');

                # Clip-Properties

                my $h = Quiq::Hash->new(
                    endFrames => undef,
                    framerate => undef,
                    pick => undef,
                    reverse => undef,
                );
                if ($prop) {
                    $h->set(split /[=\s]/,$prop);
                }
                $clipPropertyH->set($clip=>$h);
            }
            else {        
                # Range-Definitionszeile

                my $def;
                my $resumeLine = 0;
                if (/^\s/) {
                    # Fortsetzungszeile
                    $def = $_;
                    $def =~ s/^\s+//;
                    $resumeLine = 1;
                }
                else {
                    ($range,$def) = split /\s+/,$_,2;
                    if ($rangeH->exists($range) || $clipH->exists($range)) {
                        $class->throw(
                            'TIMELAPSE-00003: Duplicate range/clip key',
                            Key => $range,
                            File => $file,
                        );
                    }

                    if ($clip) {
                        # Range-Bezeichner zu Clip hinzufügen, wenn eine
                        # Clip-Definition begonnen hat ($clip ist definiert)
    
                        my $str = $clipH->get($clip);
                        if ($str) {
                            $str .= ' ';
                        }
                        $clipH->set($clip=>$str.$range);
                    }
                }

                # []-geklammerte Ausdrücke entfernen
                $def =~ s/\[(.+?)\]//g;
        
                # {}-geklammerte Ausdrücke entfernen und zu Junk-Liste
                # hinzufügen

                while ($def =~ s/\{(.+?)\}//) {
                    if ($junkExpr) {
                        $junkExpr .= ' ';
                    }
                    $junkExpr .= $1;
                }

                # Bereinigen und speichern

                $def =~ s/\s\s+/ /g; # Folgen von Whitespace zu Leerzeichen
                $def =~ s/^\s+//g;   # Whitespace am Anfang entfernen
                $def =~ s/\s+$//g;   # Whitespace am Ende entfernen

                if ($resumeLine) {
                    my $str = $rangeH->get($range);
                    if ($str) {
                        $str .= ' ';
                    }
                    $rangeH->set($range=>$str.$def);
                }
                else {                
                    $rangeH->set($range=>$def);
                }
            }
        }
        $fh->close;
    }

    return $class->SUPER::new(
        dir => $dir,
        fileA => \@files,
        clipH => $clipH,
        clipPropertyH => $clipPropertyH,
        rangeH => $rangeH,
        junkExpr => $junkExpr,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 files() - Liste der Range-Dateien

=head4 Synopsis

    @files|$fileA = $trd->files;

=head4 Returns

Liste von Datei-Pfaden. Im Skalarkontext liefere eine
Referenz auf die Liste.

=head4 Description

Liefere die Liste der Range-Dateien in sortierter Reihenfolge.

=cut

# -----------------------------------------------------------------------------

sub files {
    my $self = shift;
    my $fileA = $self->{'fileA'};
    return wantarray? @$fileA: $fileA;
}

# -----------------------------------------------------------------------------

=head3 clipKeys() - Liste der Clip-Bezeichner

=head4 Synopsis

    @keys|$keyA = $trd->clipKeys;

=head4 Returns

Liste von Clip-Bezeichnern. Im Skalarkontext liefere eine
Referenz auf die Liste.

=head4 Description

Liefere die Liste aller Clip-Bezeichner in der Reihenfolge ihrer
Definition in der Range-Datei.

=cut

# -----------------------------------------------------------------------------

sub clipKeys {
    return shift->clipH->keys;
}

# -----------------------------------------------------------------------------

=head3 clipProperties() - Hash der Clip-Properties

=head4 Synopsis

    $h = $trd->clipProperties($key);

=head4 Returns

Referenz auf Restricted-Hash

=head4 Description

Liefere eine Referenz auf den Hash mit den Properties des Clip $key.

=cut

# -----------------------------------------------------------------------------

sub clipProperties {
    my ($self,$key) = @_;
    return $self->clipPropertyH->get($key);
}

# -----------------------------------------------------------------------------

=head3 rangeKeys() - Liste der Range-Bezeichner

=head4 Synopsis

    @keys|$keyA = $trd->rangeKeys;

=head4 Returns

Liste von Range-Bezeichnern. Im Skalarkontext liefere eine
Referenz auf die Liste.

=head4 Description

Liefere die Liste aller Range-Bezeichner in der Reihenfolge ihrer
Definition in der Range-Datei.

=cut

# -----------------------------------------------------------------------------

sub rangeKeys {
    return shift->rangeH->keys;
}

# -----------------------------------------------------------------------------

=head3 rangeCount() - Anzahl der definierten Ranges

=head4 Synopsis

    $n = $trd->rangeCount;

=head4 Returns

Integer >= 0

=head4 Description

Liefere die Anzahl der Range-Bezeichner. Diese Methode kann genutzt
werden um festzustellen, ob Ranges definiert sind.

=cut

# -----------------------------------------------------------------------------

sub rangeCount {
    return shift->rangeH->hashSize;
}

# -----------------------------------------------------------------------------

=head3 expression() - Bildfolgen-Ausdruck zu Clip- oder Range-Bezeichner

=head4 Synopsis

    $expr = $trd->expression($key);

=head4 Returns

Bildfolgen-Ausdruck (String)

=head4 Description

Liefere den Bildfolgen-Ausdruck des Clip- oder Range-Bezeichners
$key. Geklammerte Teile sind nicht enthalten (siehe Abschnitt
L<Syntax|"Syntax">).

=cut

# -----------------------------------------------------------------------------

sub expression {
    my ($self,$key) = @_;

    # FIXME: Wert von clipH durch String ersetzen (im Konstruktor)
    
    if (my $expr = $self->clipH->get($key)) {
        return $expr;
    }

    my $expr = $self->rangeH->get($key);
    if (defined $expr) { # Leerstring ist möglich
        return $expr;
    }

    $self->throw;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

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
