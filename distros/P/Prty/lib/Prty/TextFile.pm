package Prty::TextFile;
use base qw/Prty::Object/;

use strict;
use warnings;
use utf8;

our $VERSION = 1.121;

use Prty::Option;
use Prty::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::TextFile - Textdatei als Array von Zeilen

=head1 BASE CLASS

L<Prty::Object>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Textdatei als ein
Array von Zeilen. Die Zeilen sind ihrerseits Objekte (per
Default Objekte der Klasse Prty::TextFile::Line). Die Klasse stellt
Methoden zur Manipulation des Arrays von Zeilen zur Verfügung.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $doc = $class->new($file,@opt);
    $doc = $class->new(\$str,@opt);
    $doc = $class->new(\@lines,@opt);

=head4 Options

=over 4

=item -lineClass => $class (Default: 'Prty::TextFile::Line')

Klasse, auf die die Zeilen des Dokuments geblesst werden.

=item -lineContinuation => $type (Default: keine Zeilenfortsetzung)

=over 4

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

=item -skip => $regex (Default: keiner)

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
    my $inp = shift;
    # @_: @opt

    # Optionen

    my $lineClass = 'Prty::TextFile::Line';
    my $lineContinuation = undef;
    my $skip = undef;

    if (@_) {
        Prty::Option->extract(\@_,
            -lineClass=>\$lineClass,
            -lineContinuation=>\$lineContinuation,
            -skip=>\$skip,
        );
    }

    # Lade Zeilenklasse

    eval "use $lineClass";
    if ($@) {
        $class->throw(
            q{TEXT-00001: Kann Zeilenklasse nicht laden},
            LineClass=>$lineClass,
            InternalError=>$@,
        );
    }

    my @lines;
    if (ref($inp) eq 'ARRAY') { # Zeilen in neues Dokument
        @lines = @$inp;
    }
    else { # Zeilen aus Datei oder String lesen
        my $fh = Prty::FileHandle->new('<',$inp);
        while (<$fh>) {
            chomp;
            push @lines,$lineClass->new($_,$.);
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
                    q{TEXT-00002: Ungüliger Wert für Option -lineContinuation},
                    Value=>$lineContinuation,
                );
            }
        }
    }

    # Leerzeilen am Ende entfernen
    pop @lines while @lines && $lines[-1]->isEmpty;

    return bless \@lines,$class;
}

# -----------------------------------------------------------------------------

=head2 Accessors

=head3 lines() - Liste der Zeilen

=head4 Synopsis

    @arr|$arr = $doc->lines(\@lines);

=head4 Description

Liefere die Liste der Zeilen der Textdatei.
Im Skalarkontext liefere eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub lines {
    my $self = shift;
    return wantarray? @$self: $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation

=head4 Synopsis

    $str = $doc->dump($format);
    $str = $doc->dump;

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

=head3 removeEmptyLines() - Entferne Leerzeilen am Anfang

=head4 Synopsis

    $doc->removeEmptyLines;

=head4 Description

Entferne Leerzeilen am Anfang. Die Methode liefert
keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub removeEmptyLines {
    my $self = shift;
    my $lines = $self->lines;
    shift @$lines while $lines->[0] && $lines->[0]->isEmpty;
    return;
}

# -----------------------------------------------------------------------------

=head3 shiftLine() - Shifte erste Zeile

=head4 Synopsis

    $line = $doc->shiftLine;

=head4 Description

Entferne die erste Zeile aus dem Dokument und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub shiftLine {
    my $self = shift;
    return shift @{$self->lines};
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.121

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
