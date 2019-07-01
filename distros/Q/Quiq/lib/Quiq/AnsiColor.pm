package Quiq::AnsiColor;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Term::ANSIColor ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::AnsiColor - Erzeuge Text mit/ohne ANSI Colorcodes

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

    use Quiq::AnsiColor;
    
    my $a = Quiq::AnsiColor->new(-t STDOUT);
    printf "%s\n",$a->str('bold white on_cyan','Hello, world!');

=head1 DESCRIPTION

Die  Klasse erlaubt es, Textausgaben - die typischerweise aufs
Terminal gehen - mit ANSI Colorcodes auszuzeichnen und diese
Auszeichnung zentral an- und ab-zuschalten. Die An- oder Abschaltung
erfolgt bei Aufruf des Konstruktors.

=head2 Terminal-Eigenschaften

    Allgemein    Vordergrund  Hintergrund
    -----------  -----------  -----------
    dark         black        on_black
    bold         red          on_red
    underline    green        on_green
    blink        yellow       on_yellow
    reverse      blue         on_blue
    concealed    magenta      on_magenta
    reset        cyan         on_cyan
                 white        on_white

Es kann eine Kombination aus Eigenschaften angegeben werden. Mehrere
aus der Rubrik "Allgemein", eine aus der Rubrik "Vordergrund",
eine aus der Rubrik "Hintergrund". Werden mehrere Eigenschaften
angegeben, werden diese durch Leerzeichen getrennt.

Beispiele: 'bold reverse' oder 'dark red on_green'

=head2 Texte mit Colorcodes weiter verarbeiten

Die im folgenden genannten Programme C<aha>, C<wkhtmltopdf> sind im
Debian-Repository enthalten.

=head3 Nach PDF wandeln

    $ PROGRAM | aha | wkhtmltopdf - FILE.pdf

=head3 Drucken

    $ PROGRAM | aha | wkhtmltopdf - - | lpr

=head3 Im Pager anzeigen

    $ PROGRAM | less -R

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $a = $class->new;
    $a = $class->new($bool);

=head4 Arguments

=over 4

=item $bool (Default: 1)

Wenn wahr, findet eine Auszeichnung mit ANSI Colorcodes durch die
Klasse statt, wenn falsch, nicht. Ist das Argument nicht angegeben,
ist dies gleichbedeutend mit wahr.

=back

=head4 Returns

AnsiColor-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück. Durch
den Parameter $bool wird entschieden, ob die Ausgabe mit oder ohne
ANSI Colorcodes erfolgt.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $bool = @_? shift: 1;

    return bless \$bool,$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 active() - Farbdarstellung eingeschaltet?

=head4 Synopsis

    $bool = $a->active;

=head4 Returns

Bool

=head4 Description

Liefere wahr, wenn ANSI Colorcodes aktiviert sind, anderfalls falsch.

=cut

# -----------------------------------------------------------------------------

sub active {
    return ${$_[0]};
}

# -----------------------------------------------------------------------------

=head3 str() - Formatiere String mit Colorcodes

=head4 Synopsis

    $str = $a->str($attr,$str);

=head4 Arguments

=over 4

=item $attr

Attribut-Spezifikation gemäß Term::ANSIColor (siehe auch
L<Terminal-Eigenschaften|"Terminal-Eigenschaften">).

=item $str

Zeichenkette, die mit ANSI Colorcodes formatiert wird.

=back

=head4 Returns

Zeichenkette mit ANSI Colorcodes (String)

=head4 Description

Formatiere Zeichenkette $str mit ANSI Colorcodes gemäß
Spezifikation $attr und liefere das Resultat zurück. Die
Colorcodes werden der Zeichenkette vorangestellt und mit dem
Colorcode 'reset' beendet. Ist die Erzeugung von Colorcodes
abgeschaltet, wird die Zeichenkette unverändert geliefert.

=cut

# -----------------------------------------------------------------------------

sub str {
    my ($self,$attr,$str) = @_;

    if ($$self) {
        return Term::ANSIColor::color($attr).$str.
            Term::ANSIColor::color('reset');
    }
    
    return $str;
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
