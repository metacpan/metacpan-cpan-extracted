package Quiq::LineProcessor;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Quiq::Option;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::LineProcessor - Verarbeite Datei als Array von Zeilen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Datei als ein Array von
Zeilen. Die Zeilen sind ihrerseits Objekte (per Default Objekte
der Klasse Quiq::LineProcessor::Line). Die Klasse stellt
Methoden zur Manipulation des Arrays von Zeilen zur Verfügung.

=head2 Fehlerbehandlung

Für eine Fehlerbehandlung können die Methoden $par->input()
und $line->number() genutzt werden:

    $class->throw(
        'SDOC-00001: K\{} and k\{} are not supported anymore',
        Input => ''.$par->input,
        Line => $line->number,
    );

produziert (z.B.)

    Exception:
        SDOC-00001: K{} and k{} is not supported anymore
    Input:
        /tmp/test.sdoc
    Line:
        20
    Stacktrace:
        ...

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Textdatei-Objekt

=head4 Synopsis

    $par = $class->new($file,@opt);
    $par = $class->new(\$str,@opt);
    $par = $class->new(\@lines,@opt);

=head4 Options

=over 4

=item -lineClass => $class (Default: 'Quiq::LineProcessor::Line')

Klasse, auf die die Zeilen des Dokuments geblesst werden.

=item -lineContinuation => $type (Default: undef)

Art der Zeilenfortsetzung. Mögliche Werte:

=over 4

=item undef

Keine Zeilenfortsetzung.

=item 'backslash'

Endet eine Zeile mit einem Backslash, entferne Whitespace am
Anfang der Folgezeile und füge den Rest zur Zeile hinzu.

Dies kann für eine Zeile unterdrückt werden, indem der Backslash am
Ende der Zeile durch einen davorgestellten Backslash maskiert wird.
In dem Fall wird statt einer Fortsetzung der Zeile der maskierende
Backslash entfernt.

=item 'whitespace'

Beginnt eine Zeile mit einem oder mehreren Leerzeichen oder TABs, wird
sie zur vorhergehenden Zeile hinzugefügt. Die Leerzeichen und TABs am
Zeilenanfang werden entfernt. Die Teile werden mit \n als Trenner
zusammengefügt.

=back

=item -skip => $regex (Default: undef)

Überlies Zeilen, die Regex $regex erfüllen.

=back

=head4 Description

Instantiiere ein Dokument-Objekt aus Datei $file, aus Text
$text oder aus den Zeilen @lines und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $input = shift;
    # @_: @opt

    # Optionen

    my $encoding;
    my $lineClass = 'Quiq::LineProcessor::Line';
    my $lineContinuation = undef;
    my $skip = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
            -encoding => \$encoding,
            -lineClass => \$lineClass,
            -lineContinuation => \$lineContinuation,
            -skip => \$skip,
        );
    }

    # Lade Zeilenklasse

    eval "use $lineClass";
    if ($@) {
        $class->throw(
            'TEXT-00001: Kann Zeilenklasse nicht laden',
            LineClass => $lineClass,
            InternalError => $@,
        );
    }

    my @lines;
    my $inputAsString = "$input"; # Wir wollen die Bezeichnung
    if (ref($input) eq 'ARRAY') { # Zeilen in neues Dokument
        @lines = @$input;
    }
    else { # Zeilen aus Datei oder String lesen
        my $fh = Quiq::FileHandle->new('<',$input);
        if ($encoding) {
            $fh->binmode(":encoding($encoding)");
        }
        while (<$fh>) {
            chomp;
            push @lines,$lineClass->new($_,$.,\$inputAsString);
        }
        $fh->close;
    }

    # Kommentarzeilen entfernen und Fortsetzungszeilen zusammenfassen

    for (my $i = 0; $i < @lines; $i++) {
        my $text = $lines[$i]->text;
        if ($skip && $text =~ /$skip/) {
            # Kommentarzeile entfernen
            splice @lines,$i--,1;
            next;
        }

        if ($lineContinuation) {
            if ($lineContinuation eq 'backslash') {
                my $modified = 0;
                while ($text =~ s/\\$// && $i+1 < @lines) {
                    $modified++;
                    last if $text =~ /\\$/;
                    my $text2 = $lines[$i+1]->text;
                    $text2 =~ s/^\s+//; # WS am Anfang entfernen
                    $text .= $text2;
                    splice @lines,$i+1,1;
                }
                $lines[$i]->text($text) if $modified;
            }
            elsif ($lineContinuation eq 'whitespace') {
                if ($text =~ s/^[ \t]+/\n/) {
                    $lines[$i-1]->append($text);
                    # Fortsetzungszeile entfernen
                    splice @lines,$i--,1;
                }
            }
            else {
                $class->throw(
                    'TEXT-00002: Ungüliger Wert für Option -lineContinuation',
                    Value => $lineContinuation,
                );
            }
        }
    }

    # Leerzeilen am Ende entfernen
    pop @lines while @lines && $lines[-1]->isEmpty;

    my $self = $class->SUPER::new(
        input  =>  $inputAsString, # Wir wollen die Bezeichnung
        lineClass  =>  $lineClass,
        lineA  =>  \@lines,
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 input() - Bezeichnung Eingabequelle

=head4 Synopsis

    $input = $par->input;

=head4 Description

Liefere die Bezeichnung der Eingabequelle. Dies kann ein Dateiname
oder eine stringifizierte String- oder Arrayreferenz sein.

=cut

# -----------------------------------------------------------------------------

sub input {
    return shift->{'input'};
}

# -----------------------------------------------------------------------------

=head3 lineClass() - Zeilen-Klasse

=head4 Synopsis

    $lineClass = $par->lineClass;

=head4 Description

Liefere die Zeilen-Klasse.

=cut

# -----------------------------------------------------------------------------

sub lineClass {
    return shift->{'lineClass'};
}

# -----------------------------------------------------------------------------

=head3 lines() - Liste der Zeilen

=head4 Synopsis

    @lines | $lineA = $par->lines(\@lines);

=head4 Description

Liefere die Liste der Zeilen der Datei. Im Skalarkontext liefere
eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub lines {
    my $self = shift;
    my $lineA = $self->{'lineA'};
    return wantarray? @$lineA: $lineA;
}

# -----------------------------------------------------------------------------

=head2 Operationen

=head3 shiftLine() - Entferne und liefere erste Zeile

=head4 Synopsis

    $line = $par->shiftLine;

=head4 Description

Entferne die erste Zeile aus dem Dokument und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub shiftLine {
    my $self = shift;
    return shift @{$self->lines};
}

# -----------------------------------------------------------------------------

=head3 shiftLineIfEq() - Entferne erste Zeile, wenn bestimmter Inhalt

=head4 Synopsis

    $line = $par->shiftLineIfEq($str);

=head4 Description

Entferne die erste Zeile aus dem Dokument und liefere diese zurück,
sofern ihr Inhalt eq $str ist.

=cut

# -----------------------------------------------------------------------------

sub shiftLineIfEq {
    my ($self,$str) = @_;
    my $lineA = $self->lines;
    return @$lineA && $lineA->[0]->text eq $str? shift @{$self->lines}: undef;
}

# -----------------------------------------------------------------------------

=head3 removeEmptyLines() - Entferne Leerzeilen am Anfang

=head4 Synopsis

    $par->removeEmptyLines;

=head4 Description

Entferne Leerzeilen am Anfang. Die Methode liefert
keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub removeEmptyLines {
    my $self = shift;
    my $lines = $self->lines;
    shift @$lines while @$lines && $lines->[0]->isEmpty;
    return;
}

# -----------------------------------------------------------------------------

=head2 Externe Repräsentation

=head3 dump() - Erzeuge externe Repräsentation

=head4 Synopsis

    $str = $par->dump($format);
    $str = $par->dump;

=head4 Description

Erzeuge eine externe Dokumentrepräsentation in Format $format
für das gesamte Dokument und liefere diese zurück.

B<Formate>

Siehe $ln->dump()

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift || 0;

    my $str = '';
    for my $line (@{$self->lines}) {
        $str .= $line->dump($format);
    }

    return $str;
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
