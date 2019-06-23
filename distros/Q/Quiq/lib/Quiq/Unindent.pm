package Quiq::Unindent;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Unindent - Entferne Einrückung von "Here Document" oder String-Literal

=head1 SYNOPSIS

Klasse laden:

    use Quiq::Unindent;

Eingerücktes "Here Document":

    {
        $text = Quiq::Unindent->hereDoc(<<'    EOT');
        Dies ist
        ein Text
        EOT
    
        print $text;
    }

Eingerücktes mehrzeiliges String-Literal:

    {
        $text = Quiq::Unindent->string('
            Dies ist
            ein Text
        ');
    
        print $text;
    }

Resultat in beiden Fällen:

    Dies ist
    ein Text

=head1 DESCRIPTION

Die Klasse stellt Methoden zur Verfügung, mit denen die in der
Regel unerwünschte Einrückung von eingerückten mehrzeiligen
String-Literalen und "Here Documents" entfernt werden kann.

=head1 METHODS

=head2 Klassenmethoden

=head3 hereDoc() - Entferne Einrückung von "Here Document"

=head4 Synopsis

    $str = $class->hereDoc(<<'EOT');
        <Text>
    EOT

=head4 Description

Entferne von allen Zeilen die tiefste Einrückung, die allen Zeilen
gemeinsam ist, und liefere die resultierende Zeichenkette zurück,
wobei

=over 2

=item *

alle Sub-Einrückungen erhalten bleiben

=item *

alle Leerzeilen erhalten bleiben, auch am Anfang und am Ende

=back

Ist der Ende-Marker eingerückt, muss dessen Einrückung bei der
Vereinbarung des Markers angegeben werden. Siehe C<<< <<' EOT' >>> in
den Beispielen.

=head4 Examples

=over 4

=item 1.

Gegenüberstellung der Syntax

    {
        $text = Quiq::Unindent->hereDoc(<<'    EOT');
        Dies ist
        ein Text
        EOT
    }

ist äquivalent zu

    {
        $text = <<'EOT';
    Dies ist
    ein Text
    EOT
    }

=item 2.

Sub-Einrückungen und Leerzeilen

    {
        $text = Quiq::Unindent->hereDoc(<<'    EOT');
    
          Dies ist der
        erste Absatz.
    
          Dies ist ein
        zweiter Absatz.
    
        EOT
    }

ergibt

    |
    |  Dies ist der
    |erste Absatz.
    |
    |  Dies ist ein
    |zweiter Absatz.
    |

d.h. Sub-Einrückungen und Leerzeilen bleiben erhalten.

=back

=cut

# -----------------------------------------------------------------------------

sub hereDoc {
    my $class = shift;
    my $str = shift // return '';

    # Wir brauchen uns nur mit dem String befassen, wenn das erste
    # Zeichen ein Whitespacezeichen ist. Wenn dies nicht der Fall
    # ist, existiert keine Einrückung, die wir entfernen müssten.

    if ($str =~ /^\s/) {
        my $ind;
        while ($str =~ /^([ \t]*)(.?)/gm) {
            if (length $2 == 0) {
                # Leerzeilen und Whitespace-Zeilen übergehen wir
            }
            elsif (!defined $ind || length $1 < length $ind) {
                $ind = $1;
                if (!$ind) {
                    # Zeile ohne Einrückung gefunden
                    last;
                }
            }
        }
        if ($ind) {
            # gemeinsame Einrückung von allen Zeilen entfernen
            $str =~ s/^$ind//gm;
        }
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 string() - Entferne Einrückung von mehrzeiligem String-Literal

=head4 Synopsis

    $str = $class->string('
        <Text>
    ');

=head4 Description

Wie Methode L<hereDoc|"hereDoc() - Entferne Einrückung von "Here Document"">(), wobei über die Einrückung hinaus

=over 2

=item *

der erste Zeilenumbruch am Anfang entfernt wird (sofern vorhanden)

=item *

die Leerzeichen am Ende entfernt werden (sofern vorhanden)

=back

Diese (zusätzlichen) Manipulationen sorgen dafür, dass der
Leerraum entfernt wird, der dadurch entsteht, wenn die
Anführungsstriche auf einer eigenen Zeile stehen.

=head4 Examples

=over 4

=item 1.

Gegenüberstellung der Syntax:

    {
        $text = Quiq::Unindent->string('
            Dies ist
            ein Text
        ');
    }

ist äquivalent zu

    {
        $text = 'Dies ist
    ein Text
    ';
    }

=item 2.

Varianten

    $text = Quiq::Unindent->string(q~
        Dies ist
        ein Text
    ~);
    
    $text = Quiq::Unindent->string("
        Dies ist
        ein Text mit $variable
    ");
    
    $text = Quiq::Unindent->string(qq~
        Dies ist
        ein Text mit $variable
    ~);

=back

=cut

# -----------------------------------------------------------------------------

sub string {
    my $class = shift;
    my $str = shift // return '';

    $str =~ s/^\n//;
    $str =~ s/ +$//;

    return $class->hereDoc($str);
}

# -----------------------------------------------------------------------------

=head3 trim() - Entferne Einrückung und Whitespace am Anfang und Ende

=head4 Synopsis

    $strOut = $class->trim($strIn);

=head4 Description

Wie die Methoden L<hereDoc|"hereDoc() - Entferne Einrückung von "Here Document"">() und L<string|"string() - Entferne Einrückung von mehrzeiligem String-Literal">(), wobei über die
Einrückung hinaus

=over 2

=item *

alle Leerzeilen am Anfang entfernt werden

=item *

jeglicher Leerraum am Ende entfernt wird

=back

Diese (zusätzlichen) Manipulationen sorgen dafür, dass der Text
als solches - d.h. ohne Einrückung und ohne Leerraum am Anfang und
am Ende - geliefert wird.

Die Methode ist speziell für die I<interne> Bearbeitung eines
mehrzeiligen, ggf. mit einer Einrückung versehenen Parameterns
geeignet.

=head4 Examples

=over 4

=item 1.

Leerraum am Anfang und am Ende wird entfernt

    {
        $text = Quiq::Unindent->trim("
    
            SELECT
                *
            FROM
                person
            WHERE
                nachname = 'Schulz'
    
        ");
    }

ergibt

    |SELECT
    |    *
    |FROM
    |    person
    |WHERE
    |    nachname = 'Schulz'
                            ^
                            kein Newline

=item 2.

Interne Anwendung

    sub select {
        my ($self,$stmt) = @_;
    
        $stmt = Quiq::Unindent->trim($stmt);
        if ($self->debug) {
            warn $stmt,"\n";
        }
        ...
    }

Aufruf mit eingerücktem String-Literal, das I<intern> behandelt wird:

    $db->select("
        SELECT
            *
        FROM
            person
        WHERE
            nachname = 'Schulz'
    ");

=back

=cut

# -----------------------------------------------------------------------------

sub trim {
    my $class = shift;
    my $str = shift // return '';

    $str =~ s/^\s*\n//;
    $str =~ s/\s+$//;

    return $class->hereDoc($str);
}

# -----------------------------------------------------------------------------

=head3 trimNl() - Trim plus Newline

=head4 Synopsis

    $strOut = $class->trimNl($strIn);

=head4 Description

Wie die Methode L<trim|"trim() - Entferne Einrückung und Whitespace am Anfang und Ende">(), jedoch wird am Ende genau ein Newline
angehängt, sofern der Sting nicht leer ist.

=cut

# -----------------------------------------------------------------------------

sub trimNl {
    my $class = shift;
    my $str = shift // return '';

    $str = $class->trim($str);
    if ($str ne '') {
        $str .= "\n";
    }

    return $str;
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
