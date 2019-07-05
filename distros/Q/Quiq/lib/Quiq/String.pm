package Quiq::String;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Encode::Guess ();
use Encode ();
use Quiq::Option;
use Quiq::Array;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::String - Operationen auf Zeichenketten

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Eigenschaften

=head3 maxLineLength() - Länge der längsten Zeile

=head4 Synopsis

    $len = $class->maxLineLength($text);

=head4 Arguments

=over 4

=item $text

Ein String, typischerweise mehrzeilig.

=back

=head4 Returns

Länge der längsten Zeile (Integer)

=head4 Description

Ermittele die Länge der längsten Zeile und liefere diese zurück. Newline
wird nicht mitgezählt.

=cut

# -----------------------------------------------------------------------------

sub maxLineLength {
    my ($class,$text) = @_;

    my $maxLen = 0;
    for (split /\n/,$text) {
        chomp;
        my $l = length;
        if ($l > $maxLen) {
            $maxLen = $l;
        }
    }

    return $maxLen;
}

# -----------------------------------------------------------------------------

=head2 Encoding

=head3 autoDecode() - Auto-dekodiere Zeichenkette

=head4 Synopsis

    $str = $class->autoDecode($str);
    $str = $class->autoDecode($str,$otherEncoding);

=head4 Description

Analysiere Zeichenkette $str hinsichtlich ihres Character-Encodings
und dekodiere sie entsprechend. Unterschieden werden:

=over 2

=item *

ASCII

=item *

UTF-8

=item *

UTF-16/32 mit BOM

=back

und $otherEncoding. Ist $otherEncoding nicht angegeben, wird
ISO-8859-1 angenommen.

=cut

# -----------------------------------------------------------------------------

sub autoDecode {
    my $class = shift;
    my $str = shift;
    my $otherEncoding = shift || 'iso-8859-1';

    # Encoding ermitteln und Text dekodieren

    # $Encode::Guess::NoUTFAutoGuess = 1;
    my $dec = Encode::Guess->guess($str);
    if (ref $dec) {
        # Wir dekodieren Unicode
        $str = $dec->decode($str);
    }
    elsif ($dec =~ /No appropriate encodings found/i) {
        # Wir dekodieren $otherEncoding
        $str = Encode::decode($otherEncoding,$str);
    }
    else {
        # Unerwarteter Fehler
        $class->throw(
            'PATH-00099: Zeichen-Dekodierung fehlgeschlagen',
            Message => $dec,
        );
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head2 Einrückung

=head3 indent() - Rücke Text ein

=head4 Synopsis

    $str2 = $class->indent($str,$indentStr,@opt);
    $class->indent(\$str,$indentStr,@opt);

=head4 Options

=over 4

=item -indentBlankLines => $bool (Default: 0)

Rücke auch Leerzeilen ein. Per Default werden nur Zeilen mit
wenigstens einem Zeichen eingerückt.

Diese Option ist nützlich, wenn die Funktion zum Auskommentieren
genutzt werden soll.

=item -strip => $bool (Default: 0)

Entferne Newlines am Anfang und Whitespace am Ende. Per Default
geschieht dies nicht.

=back

=head4 Description

Rücke den Text $str um Zeichenkette $indentStr ein und liefere
das Resultat zurück.

Die Einrück-Zeichenkette $indentStr wird jeder Zeile von $str
hinzugefügt, außer Leerzeilen.

=head4 Example

=over 2

=item *

Texteinrückung um vier Leerzeichen

    $class->indent($txt,' ' x 4);
    
    |Dies ist                   |    Dies ist
    |ein Test-   - wird zu ->   |    ein Test-
    |Text.                      |    Text.

=back

=cut

# -----------------------------------------------------------------------------

sub indent {
    my $class = shift;
    my $str = shift;
    my $indentStr = shift;
    # @_: @opt

    # Optionen

    my $indentBlankLines = 0;
    my $strip = 0;
    if (@_) {
        Quiq::Option->extract(\@_,
            -indentBlankLines => \$indentBlankLines,
            -strip => \$strip,
        );
    }

    # Verarbeiten

    my $ref = ref $str? $str: \$str;

    if ($strip) {
        $$ref =~ s/^\n+//; # Newlines am Anfang entfernen
        $$ref =~ s/\s+$//; # Whitespace am Ende entfernen
    }

    if (defined $indentStr) {
        if ($indentBlankLines) {
            # alle Zeilen einrücken
            $$ref =~ s/^/$indentStr/mg;
        }
        else {
            # Leerzeilen nicht einrücken
            $$ref =~ s/^(.)/$indentStr$1/mg;
        }
    }

    return $str unless ref $str;
}

# -----------------------------------------------------------------------------

=head3 determineIndentation() - Einrücktiefe eines Textes

=head4 Synopsis

    $n = $class->determineIndentation($str);

=head4 Description

Ermittele die Einrücktiefe des Textes $str und liefere diese zurück.
Die Einrücktiefe ist der größte gemeinsame Teiler aller
Zeilen-Einrückungen. Beispiel:

    |Dies
    |    ist
    |       ein
    |           Test

Einrücktiefe ist 4.

WICHTIG: Für die Einrückung zählen nur Leerzeichen, keine Tabs!

=cut

# -----------------------------------------------------------------------------

sub determineIndentation {
    my ($class,$str) = @_;

    # Ermittele die verschiedenen Einrücktiefen der Zeilen

    my %ind;
    while ($str =~ /^( *)/mg) {
        $ind{length $1}++;
    }

    return Quiq::Array->gcd([keys %ind]);
}

# -----------------------------------------------------------------------------

=head3 reduceIndentation() - Reduziere Einrücktiefe eines Textes

=head4 Synopsis

    $str = $class->reduceIndentation($n,$str);
    $class->reduceIndentation($n,\$str);

=head4 Description

Reduziere die Einrücktiefe des Textes $str auf Tiefe $n.

=head4 Example

Text:

    |Dies
    |    ist
    |        ein
    |            Test

Reduktion auf Einrücktiefe 2:

    Quiq::String->reduceIndentation(2,$str);

Resultat:

    |Dies
    |  ist
    |    ein
    |      Test

=cut

# -----------------------------------------------------------------------------

sub reduceIndentation {
    my ($class,$n,$arg) = @_;

    my $ref = ref $arg? $arg: \$arg;
    
    my $m = $class->determineIndentation($$ref);
    if ($m) {
        if ($m < $n || $m%$n) {
            $class->throw(
                'STRING-00001: Einrücktiefe kann nicht reduziert werden',
                TextIndentation => $m,
                WantedIndentation => $n,
            );
        }
        elsif ($m > $n) {
            my $div = $m/$n;
            $$ref =~ s|^( +)|' ' x (length($1)/$div)|emg;
        }
    }
    
    return ref $arg? (): $$ref;
}

# -----------------------------------------------------------------------------

=head3 removeIndentation() - Entferne Text-Einrückung

=head4 Synopsis

    $str = $class->removeIndentation($str,@opt); # [1]
    $class->removeIndentation(\$str,@opt);       # [2]

=head4 Options

=over 4

=item -addNL => $bool (Default: 0)

Nach dem Entfernen aller NEWLINEs am Ende füge ein NEWLINE hinzu.

=back

=head4 Description

[1] Entferne Text-Einrückung aus Zeichenkette $str und liefere das
Resultat zurück.

[2] Wird eine Referenz auf $str übergeben, wird die
Zeichenkette "in place" manipuliert und nichts zurückgegeben.

=over 2

=item *

NEWLINEs am Anfang werden entfernt.

=item *

Whitespace (SPACEs, TABs, NEWLINEs) am Ende wird entfernt.
Das Resultat endet also grundsätzlich nicht mit einem NEWLINE.

=item *

Die Methode kehrt zurück, wenn $str anschließend nicht mit wenigstens
einem Whitespace-Zeichen beginnt, denn dann existiert keine
Einrückung, die zu entfernen wäre.

=item *

Die Einrückung von $str ist die längste Folge von SPACEs
und TABs, die allen Zeilen von $str gemeinsam ist,
ausgenommen Leerzeilen. Diese Einrückung wird am Anfang
aller Zeilen von $str entfernt.

=item *

Eine Leerzeile ist eine Zeile, die nur aus Whitespace besteht.

=back

=head4 Example

=over 2

=item *

Einrückung entfernen, Leerzeile übergehen:

    |
    |  Dies ist
    |              <- Leerzeile ohne Einrückung
    |  ein Test-
    |  Text.
    |

wird zu

    |Dies ist
    |
    |ein Test-
    |Text.

=item *

Tiefere Einrückung bleibt bestehen:

    |
    |    Dies ist
    |  ein Test-
    |  Text.
    |

wird zu

    |  Dies ist
    |ein Test-
    |Text.

=back

=cut

# -----------------------------------------------------------------------------

sub removeIndentation {
    my $class = shift;
    my $arg = shift;
    # @_: @opt

    my $ref = ref $arg? $arg: \$arg;

    my $addNL = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -addNL => \$addNL,
        );
    } 

    if (defined $$ref) {
        $$ref =~ s/^\n+//;
        $$ref =~ s/\s+$//;
        if ($addNL && $$ref) {
            $$ref .= "\n";
        }

        # Wir brauchen uns nur mit dem String befassen, wenn
        # das erste Zeichen ein Whitespacezeichen ist. Wenn dies nicht
        # der Fall ist, existiert keine Einrückung.

        if ($$ref =~ /^\s/) {
            my $ind;
            while ($$ref =~ /^([ \t]*)(.?)/gm) {
                next if length $2 == 0; # leere Zeile oder nur Whitespace
                $ind = $1 if !defined $ind || length $1 < length $ind;
                last if !$ind;
            }
            $$ref =~ s/^$ind//gm if $ind;
        }
    }

    return ref $arg? (): $$ref;
}

# -----------------------------------------------------------------------------

=head3 removeIndentationNl() - Entferne Text-Einrückung

=head4 Synopsis

    $str = $class->removeIndentationNl($str,@opt); # [1]
    $class->removeIndentationNl(\$str,@opt);       # [2]

=cut

# -----------------------------------------------------------------------------

sub removeIndentationNl {
    my $class = shift;
    my $arg = shift;
    # @_: @opt

    my $ref = ref $arg? $arg: \$arg;

    $class->removeIndentation($ref);
    if (defined($$ref) && $$ref ne '') {
        $$ref .= "\n";
    }
    
    return ref $arg? (): $$ref;
}

# -----------------------------------------------------------------------------

=head2 Kommentare

=head3 removeComments() - Entferne Kommentare aus Quelltext

=head4 Synopsis

    $newCode = $this->removeComments($code,$start);
    $newCode = $this->removeComments($code,$start,$stop);

=head4 Description

Entferne alle Kommentare aus Quelltext $code und liefere das
Resultat zurück. Die Kommentarzeichen werden durch die Parameter
$start und $stop definiert. Siehe Abschnitt Examples.

Die Methode entfernt nicht nur die Kommentare selbst, sondern
auch nachfolgenden oder vorausgehenden Whitespace, so dass
kein überflüssiger Leerraum entsteht.

Im Falle von einzeiligen Kommentaren (d.h. nur $start ist
definiert), wird vorausgesetzt, dass dem Kommentarzeichen (der
Kommentar-Zeichenkette) im Quelltext zusätzlich ein Leerzeichen
oder Tab vorausgeht, sofern es nicht am Anfang der Zeile
steht. D.h.

    my $ind = ' ' x 4; # Einrückung
                      ^ ^
                      hier müssen Leerzeichen (oder Tabs) stehen
    
    my $ind = ' ' x 4;# Einrückung
                      ^
                      Wird nicht erkannt!
    
    my $ind = ' ' x 4; #Einrückung
                       ^
                       Wird nicht erkannt!

Im Falle von mehrzeiligen Kommentaren ($start und $stop sind
definiert) ist dies das vorausgehende Leereichen nicht nötig.

=head4 Examples

HTML, XML:

    $code = Quiq::String->removeComments($code,'<!--','-->');

C, Java, CSS:

    $code = Quiq::String->removeComments($code,'/*','*/');

C++, JavaScript:

    $code = Quiq::String->removeComments($code,'//');

Shell, Perl, Python, Ruby, ...:

    $code = Quiq::String->removeComments($code,'#');

SQL:

    $code = Quiq::String->removeComments($code,'--');

=cut

# -----------------------------------------------------------------------------

sub removeComments {
    my ($this,$code,$start,$stop) = @_;

    my $regex;
    if ($start && $stop) {
        # (potentiell) mehrzeiliger Kommentar
        $regex = qr/\Q$start\E.*?\Q$stop\E/s;
    }
    else {
        # einzeilger Kommentar
        $regex = qr/(?:^|(?<=[\t ]))\Q$start\E .*/m;
    }
    
    # Spaces u. Tabs an Zeilenenden entfernen
    $code =~ s|[\t ]+$||mg;

    # Entferne alle Kommentare aus dem Quelltext und speichere die
    # übrigbleibenden Fragmente in einem Array
    my @frag = split m|$regex|s,$code;
    
    if (@frag) {
        if ($frag[-1] =~ /^$/) {
            # End-Kommentar, da das letzte Element "leer" ist. Ein
            # End-Kommentar zeichnet sich dadurch aus, dass wir
            # Leerzeilen ggf. *davor* entfernen müssen. Vorgehen:
            # 1) Wir entfernen das letzte Element
            # 2) Wir entfernen Whitspace am Ende des vorhergehenden
            #    Elements, bis auf ein Newline, falls vorhanden
            pop @frag;
            $frag[-1] =~ s/\s+$/substr($&,0,1) eq "\n"? "\n": ''/e;
        }

        for (my $i = 0; $i < @frag-1; $i++) {
            # Wir entfernen alle Spaces und Tabs, die vor dem Kommentar stehen
            $frag[$i] =~ s/([\t ]+)$//;

            if ($frag[$i] eq '' || substr($frag[$i],-1,1) eq "\n") {
                # Ganzzeiliger Kommentar
    
                # Einrückung des (ganzzeiligen) Kommentars vom linken Rand
                my $ind = $1;

                my ($prevInd,$prevContent) = $frag[$i] =~ /([\t ]*)(.*)$/;
                if ($ind && $prevContent && $ind eq $prevInd) {
                    # Die vorhergehende Zeile ist keine Leerzeile (sie hat
                    # Content) und ist identisch eingerückt wie der Kommentar:
                    # Wir entfernen nur den Zeilenumbruch der Zeile.
                    $frag[$i+1] =~ s/^\n//;
                }
                else {
                    # Die vorhergehende Zeile ist eine Leerzeile oder
                    # hat anders eingerückten Content: Wir entfernen den
                    # Zeilenumbruch der Zeile und alle folgenden Leerzeilen.
                    $frag[$i+1] =~ s/^\n+//;
                }
            }
            else {
                # Teilzeiliger Kommentar: nichts zu tun, da der Kommentar
                # und der Leerraum davor bereits entfernt ist
            }
        }
    }

    return join('',@frag);
}

# -----------------------------------------------------------------------------

=head2 Quoting

=head3 quote() - Fasse Zeichenkette in Single Quotes ein

=head4 Synopsis

    $quotedStr = $class->quote($str);

=head4 Description

Fasse Zeichenkette $str in einfache Anführungsstriche (') ein und liefere
das Resultat zurück. Enthält die Zeichenkette bereits einfache
Anführungsstriche, werden diese per Backslash geschützt.

=cut

# -----------------------------------------------------------------------------

sub quote {
    my ($class,$str) = @_;

    $str =~ s/'/\\'/g;
    $str = "'$str'";

    return $str;
}

# -----------------------------------------------------------------------------

=head2 Umbruch

=head3 wrap() - Umbreche Fließtext

=head4 Synopsis

    $text = $class->wrap($text,@opt);

=head4 Options

=over 4

=item -width => $n (Default: 70)

Maximale Zeilenbreite des resultierenden Fließtextes (sofern kein
einzelnes Wort länger als die Zeilenbreite ist).

=back

=head4 Description

Umbreche Fließext $text, so dass die Zeilenlänge $width möglichst
nicht überschritten wird. Sie kann überschritten werden, wenn ein
Wort länger als $width ist, sonst ist die Zeilenlänge <= $width.

Whitespace:

=over 2

=item *

Whitespace am Anfang und am Ende von $text wird entfernt

=item *

Folgen von Whitespace-Zeichen innerhalb von $text werden zu
einem Whitespace-Zeichen reduziert

=back

Paragraphen:

Ist der Text in Paragraphen organisiert und soll dies erhalten
bleiben, muss jeder Paragraph einzeln umbrochen werden.

=head4 Example

Maximale Zeilenlänge auf 12 Zeichen begrenzen:

    $txt = "Dies ist ein Test mit einem kurzen Text.";
    $txt = Quiq::String->wrap($txt,-width=>12);
    # =>
    Dies ist ein
    Test mit
    einem kurzen
    Text.

=cut

# -----------------------------------------------------------------------------

sub wrap {
    my $class = shift;
    my $text = shift;
    # @_: @opt

    # Optionen

    my $width = 70;
    if (@_) {
        Quiq::Option->extract(\@_,
            -width => \$width,
        );
    }

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    my @words = split /\s+/,$text;

    my $newText = '';
    my $line = '';
    while (my $word = shift @words) {
        my $l = length $line;
        if ($l == 0) {
            if (length($word) > $width) {
                $newText .= "$word\n";
            }
            else {
                $line .= $word;
            }
        }
        elsif ($l+length($word)+1 > $width) {
            $newText .= "$line\n";
            $line = $word;
        }
        else {
            $line .= " $word";
        }
    }        
    if ($line) {
        $newText.= $line;
    }

    return $newText;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
