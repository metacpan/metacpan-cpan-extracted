package Quiq::AsciiTable;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Unindent;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::AsciiTable - ASCII-Tabelle parsen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabelle, die in Form
eines ASCII-Texts gegeben ist. Diese Darstellung wird an den
Konstruktor übergeben, von diesem geparst und inhaltlich
analysiert. Die Klasse stellt Methoden zur Verfügung, um die
Eigenschaften der Tabelle abzufragen.

=head2 Aufbau einer ASCII-Tabelle

Eine ASCII-Tabelle hat den allgemeinen Aufbau:

    Right Left Center
    ----- ---- ------
        1 A      A
       21 AB    AB
      321 ABC   ABC
     4321 ABCD  ABCD

Die Tabelle besteht aus einem Tabellen-Kopf und einem
Tabellen-Körper. Der Kopf enthält die Kolumnen-Titel und der
Körper die Kolumnen-Daten. Die beiden Bereiche werden durch eine
Trennzeile aus Bindestrichen (-) und Leerzeichen ( )
getrennt. Außer der Trennung in Kopf und Körper definiert die
Trennzeile durch die Bindestriche die Anzahl, Lage und
Breite der einzelnen Kolumnen.

Obige Tabelle besitzt z.B. drei Kolumnen: Die erste Kolumne ist 5
Zeichen breit und reicht von Zeichenposition 0 bis 4. Die zweite
Kolumne ist 4 Zeichen breit und reicht von Zeichenposition
6 bis 9. Die dritte Kolumne ist 6 Zeichen breit und reicht von
Zeichenpostion 11 bis 16. Die Positionsangaben sind zeilenbezogen
und 0-basiert.

Aus der Anordnung der Werte in einer Kolumne - I<sowohl im Kopf als
auch im Körper> - ergibt sich, ob die Kolumne links, rechts oder
zentriert ausgerichtet ist. Bei einer links ausgerichteten
Kolumne belegen I<alle> (nichtleeren) Werte die erste Zeichenpositon.
Bei einer rechts ausgerichteten Kolumne belegen I<alle> (nichtleeren)
Werte die letzte Zeichenpositon. Bei einer zentrierten Kolumne
sind die Werte weder eindeutig links noch rechts ausgerichtet.

Der Tabellen-Kopf, also die Titel, können mehrzeilig sein:

    Right Left

    Aligned Aligned Centered
    ------- ------- --------
          1 A          A
         21 AB         AB
        321 ABC        ABC
       4321 ABCD      ABCD

Die Titel sind optional, können also auch fehlen:

    ----- ---- ------
        1 A      A
       21 AB    AB
      321 ABC   ABC
     4321 ABCD  ABCD

Die Kolumnenwerte können mehrzeilig sein:

    Right   Left

    Aligned   Aligned          Centered
    -------   --------------   --------
          1   This is             A
              the first row
    
          2   Second row          B
    
          3   The third           C
              row

Bei einer Tabelle mit mehrzeiligen Kolumnenwerten werden die
Zeilen durch Trennzeilen getrennt, gleichgültig, ob die einzelne
Zeile einen mehrzeiligen Kolumnenwert enhält oder nicht (siehe
Zeile 2). Die Trennzeile kann eine einfache Leerzeile sein oder
Bindestriche enthalten wie die Trennzeile zwischen Tabellen-Kopf
und -Körper:

    Right   Left

    Aligned   Aligned          Centered
    -------   --------------   --------
          1   This is             A
              the first line
    -------   --------------   --------
          2   Second line         B
    -------   --------------   --------
          3   The third           C
              line
    -------   --------------   --------

Generell gilt ferner:

=over 2

=item *

Ist die Tabelle eingerückt, wird diese Einrückung entfernt. Die
Einrückung muss aus Leerzeichen bestehen.

=item *

Leerzeien oberhalb und unterhalb der Tabelle werden entfernt.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $tab = $class->new($str);

=head4 Arguments

=over 4

=item $str

Zeichenkette mit ASCII-Tabelle.

=back

=head4 Returns

Tabellen-Objekt

=head4 Description

Instantiiere ein Tabellen-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$str) = @_;

    # Einrückung entfernen
    $str = Quiq::Unindent->trimNl($str);

    # Zeilen einlesen
    # * In Daten- und Trennzeilen differenzieren
    # * Separator-Zeile ermitteln
    # * Feststellen, ob es sich im eine Multiline-Tabelle handelt

    my @lines;          # Zeile: [$type,$text]
    my $titles = 1;     # Titelzeile(n) vorhanden
    my $sepLine;        # Separator-Zeile unter Titel
    my $multiLine = -1; # Multizeilen-Tabelle, wenn > 0
    my $tabLineLength;  # Logische Breite einer ASCII-Tabellenzeile

    # my $fh = Quiq::FileHandle->new('<',\$str);
    # while (<$fh>) {
    #   chomp;

    for (split /\n/,$str) {
       if (/^[- ]*$/) { # Bindestrich-Zeile, Whitespace-Zeile, Leerzeile
            if (!@lines) {
                $titles = 0;
            }
                    
            # Die erste Trennzeile definiert das Kolumnenlayout
            
            if (!defined $sepLine) {
                $sepLine = $_;
                $tabLineLength = length $sepLine;
            }
            $multiLine++;
            push @lines,[0,$_];
        }
        else {
            # Datenzeile
            push @lines,[1,$_];
        }
    }
    # $fh->close;

    # Prüfe, ob die Eingabedaten eine Tabelle darstellen

    if (!$sepLine || substr($sepLine,0,1) ne '-') {
        $class->throw(
            'TABLE-00001: No table (no parting line)',
            Input => $str,
        );
    }

    # Positionen und Kolumnenbreiten bestimmen. Diese Information
    # wird aus der Separatorzeile gewonnen.
    # $type==0: Zwischenraum, $type==1: Daten
 
    my @ranges;         # [$type,$pos,$width]
    my $tableWidth = 0; # Anzahl der Kolumnen der Tabelle

    my $pos = 0;
    my @arr = split /( +)/,$sepLine;
    while (@arr) {
        my $str = shift @arr;
        my $width = length $str;
        if (substr($str,0,1) eq '-') {
            # Daten-Bereich
            push @ranges,[1,$pos,$width];
            $tableWidth++;
        }
        else {
            # Kolumnentrenner-Bereich (Spaces)
            push @ranges,[0,$pos,$width];
        }
        $pos += $width;
    }

    # Titel- und Datenzeilen bestimmen

    # Hilfsfunktion: Zeile mit Leerzeichen auffüllen

    my $pad = sub {
        my ($text,$len) = @_; # Text, Länge
        return $text .= ' ' x ($len - length $text);
    };

    # Hilfsfunktion: Daten aus Zeile extrahieren

    my $extract = sub {
        my ($text,$r) = @_; # Text, Range
        return substr $text,$r->[1],$r->[2];
    };

    my (@columns,@titles,@align,@rows);
    while (@lines) {
        my $line = shift @lines;
        if ($line->[0]) { # Datenzeile
            my $lineText = $pad->($line->[1],$tabLineLength);

            my $i = 0; # Kolumnen-Index
            for (my $j = 0; $j < @ranges; $j++) { # Range-Index
                my $r = $ranges[$j];
                if ($r->[0]) {
                    my $str = $extract->($lineText,$r);
                    
                    # Whitespace bereinigen

                    my ($wsLeft,$wsRight);
                    if ($str =~ s/^ +//) {
                        $wsLeft = 1;
                    }
                    if ($str =~ s/ +$//) {
                        $wsRight = 1;
                    }
                    if ($str eq '') {
                        # Leere Zelle
                        $wsLeft = $wsRight = 0;
                    }

                    # Ausrichtung des Kolumnenwerts ermitteln

                    if ($wsLeft && $wsRight) {
                        $align[$i]{'c'}++; # centered ' x '
                    }
                    elsif ($wsLeft) {
                        $align[$i]{'r'}++; # right ' x'
                    }
                    elsif ($wsRight) {
                        $align[$i]{'l'}++; # left 'x '
                    }
                    else {
                        $align[$i]{'u'}++; # unknown 'x'
                    }
                    
                    # Kolumnenwert speichern

                    if (defined $columns[$i] && $columns[$i] ne '' &&
                            $str ne '') {
                        $columns[$i] .= "\n";
                    }
                    $columns[$i++] .= $str;
                }
            }
            if (!$multiLine && (!$titles || @titles)) {
                push @rows,[@columns];
                @columns = ();
            }
        }
        elsif (@columns) { # Trennzeile nachdem Datenzeilen gelesen wurden
            if ($titles && !@titles) {
                @titles = @columns;
            }
            else {
                push @rows,[@columns];
            }
            @columns = ();
        }
    }
    if (@columns) {
        push @rows,[@columns];
    }

    # Kolumnen-Ausrichtung ermitteln

    for (my $i = 0; $i < @align; $i++) {
        if ($align[$i]{'c'}) {
            $align[$i] = 'c';
        }
        elsif ($align[$i]{'l'} && $align[$i]{'r'}) {
            $align[$i] = 'c';
        }
        elsif ($align[$i]{'r'}) {
            $align[$i] = 'r';
        }
        else {
            $align[$i] = 'l';
        }
    }

    return $class->SUPER::new(
        str => $str,
        width => $tableWidth,
        alignA => \@align,
        rangeA => \@ranges,
        multiLine => $multiLine,
        titleA => \@titles,
        rowA => \@rows,
    );
}

# -----------------------------------------------------------------------------

=head2 Eigenschaften

=head3 alignments() - Ausrichtung der Kolumnenwerte

=head4 Synopsis

    @align | $alignA = $tab->alignments;
    @align | $alignA = $tab->alignments($domain);

=head4 Arguments

=over 4

=item $domain (Default: 'latex')

Legt die gelieferte Wertemenge fest.

=over 4

=item 'latex'

Gelieferte Werte: 'l', 'r', 'c'.

=item 'html'

Gelieferte Werte: 'left', 'right', 'center'.

=back

=back

=head4 Returns

Liste der Kolumnenausrichtungen. Im Skalarkontext liefere eine
Referenz auf die Liste.

=head4 Description

Liefere die Liste der Kolumnenausrichtungen der Domäne $domain.
Mögliche Ausrichtungen:

=over 2

=item *

Zentriert (centered).

=item *

Rechtsbündig (right aligned).

=item *

Linksbündig (left aligned).

=back

=head4 Example

Tabelle:

    Right Left    Centered

    Aligned Aligned  Header
    ------- ------- --------
          1 A          A
         21 AB         AB
        321 ABC        ABC

Resultat:

    @align = $tab->alignments;
    # ('r','l','c')

=cut

# -----------------------------------------------------------------------------

sub alignments {
    my $self = shift;
    my $domain = shift // 'latex';

    my $alignA = $self->{'alignA'};
    if ($domain eq 'html') {
        $alignA = [map {{l=>'left',r=>'right',c=>'center'}->{$_}} @$alignA];
    }

    return wantarray? @$alignA: $alignA;
}

# -----------------------------------------------------------------------------

=head3 multiLine() - Tabelle ist MultiLine-Tabelle

=head4 Synopsis

    $bool = $tab->multiLine;

=head4 Returns

Boolean

=head4 Description

Liefere 1, wenn die Tabelle eine MultiLine-Tabelle ist, andernfalls 0.

=head4 Example

Tabelle:

    Right Left    Centered

    Aligned Aligned  Header
    ------- ------- --------
          1 Erste       A
            Zeile
    
          2 Zweite      B
            Zeile
    
          3 Dritte      C
            Zeile

Resultat:

    $multiLine = $tab->multiLine;
    # 1

=head3 rows() - Liste der Zeilen

=head4 Synopsis

    @rows | $rowA = $tab->rows;

=head4 Returns

Liste der Zeilen. Im Skalarkontext liefere eine Referenz auf die
Liste.

=head4 Example

Tabelle:

    Right Left    Centered

    Aligned Aligned  Header
    ------- ------- --------
          1 A          A
         21 AB         AB
        321 ABC        ABC

Resultat:

    @rows = $tab->rows;
    # (['1',  'A',  'A'],
    #  ['21', 'AB', 'AB'],
    #  ['321','ABC','ABC'])

=cut

# -----------------------------------------------------------------------------

sub rows {
    my $self = shift;
    my $rowA = $self->{'rowA'};
    return wantarray? @$rowA: $rowA;
}

# -----------------------------------------------------------------------------

=head3 titles() - Liste der Kolumnentitel

=head4 Synopsis

    @titles | $titleA = $tab->titles;

=head4 Returns

Liste der Kolumnentitel. Im Skalarkontext liefere eine Referenz
auf die Liste.

=head4 Example

Tabelle:

    Right Left    Centered

    Aligned Aligned  Header
    ------- ------- --------
          1 A          A
         21 AB         AB
        321 ABC        ABC

Resultat:

    @titles = $tab->titles;
    # ("Right\nAligned","Left\nAligned","Centered\nHeader")

=cut

# -----------------------------------------------------------------------------

sub titles {
    my $self = shift;
    my $titleA = $self->{'titleA'};
    return wantarray? @$titleA: $titleA;
}

# -----------------------------------------------------------------------------

=head3 width() - Anzahl der Kolumnen

=head4 Synopsis

    $n = $tab->width;

=head4 Returns

Kolumnenanzahl (Integer > 0)

=head4 Description

Liefere die Anzahl der Kolumnen der Tabelle.

=head4 Example

Tabelle:

    Right Left    Centered

    Aligned Aligned  Header
    ------- ------- --------
          1 A          A
         21 AB         AB
        321 ABC        ABC

Resultat:

    $n = $tab->width;
    # 3

=head2 Formate

=head3 asText() - Liefere ASCII-Tabelle

=head4 Synopsis

    $str = $class->asText;

=head4 Returns

ASCII-Tabelle (String)

=head4 Description

Liefere die Tabelle als Zeichenkette, wie sie dem Konstruktor
übergeben wurde, jedoch ohne Einrückung.

=cut

# -----------------------------------------------------------------------------

sub asText {
    return shift->{'str'};
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
