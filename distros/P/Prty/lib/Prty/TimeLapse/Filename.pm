package Prty::TimeLapse::Filename;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.113;

use Prty::Option;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::TimeLapse::Filename - Bildsequenz-Dateiname

=head1 BASE CLASS

L<Prty::Hash>

=head1 SYNOPSIS

    # Klasse laden
    use Prty::TimeLapse::Filename;
    
    # Instantiiere Bildsequenz-Dateinamen
    $nam = Prty::TimeLapse::Filename->new('/my/image/dir/000219-3000x2250-G0080108.jpg');
    
    # Nummer
    $n = $nam->number; # 219
    
    # Breite
    $width = $nam->width; # 3000
    
    # Höhe
    $height = $nam->height; # 2250
    
    # Extension
    $extension = $nam->extension; # 'jpg'
    
    # Name
    $name = $nam->name; # 'G0080108'

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert den Namen einer Bildsequenz-Datei.
Der Name einer Bildsequenz-Datei hat den Aufbau:

    NNNNNN-WIDTHxHEIGHT[-NAME].EXT

=head1 ATTRIBUTES

=over 4

=item number

Bildnummer

=item width

Breitenangabe

=item heigth

Höhenangabe

=item text

Text-Zusatz

=item ext

Extension

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bilddateinamen-Objekt

=head4 Synopsis

    $nam = $class->new($file);
    $nam = $class->new($n,$width,$height,$ext,@opt);

=head4 Description

Instantiiere Bilddateinamen-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=head4 Arguments

=over 4

=item $file

Pfad der Bilddatei

=item $n

Bildnummer

=item $width

Breite des Bildes

=item $heigth

Höhe des Bildes

=item $ext

Extension der Bilddatei

=back

=head4 Options

=over 4

=item -text => $str

Namenszusatz der Datei

=back

=head4 Returns

Referenz auf das Bilddateinamen-Objekt

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $file -or- $n,$width,$height,$ext,@opt

    my ($n,$width,$height,$ext,$text);
    if (@_ == 1) {
        # Dateiname

        my $file = shift;
        $file =~ s|.*/||; # Verzeichnisanteil entfernen

        ($n,my $size,$text) = split /-/,$file,3;
        $n += 0;
        if (defined $text) {
            ($text,$ext) = $text =~ /^(.*)\.([^.]+)$/;
        }
        else {
            ($size,$ext) = $size =~ /^(.*)\.([^.]+)$/;
        }
        ($width,$height) = split /x/,$size;
    }
    else {
        # Einzelangaben

        Prty::Option->extract(\@_,
            -text=>\$text,
        );
        ($n,$width,$height,$ext) = @_;
    }

    # Angaben überprüfen

    if (!$n || !$width || !$height || !$ext) {
    
        $class->throw(
            q{SEQ-00001: Illegal image sequence filename},
            number=>$n // 'undef',
            width=>$width // 'undef',
            height=>$height // 'undef',
            extension=>$ext // 'undef',
        );
    }
    
    return $class->SUPER::new(
        number=>$n,
        width=>$width,
        height=>$height,
        text=>$text,
        extension=>$ext,
    );
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 number() - Nummer der Bilddatei

=head4 Synopsis

    $n = $nam->number;

=head4 Description

Liefere die Nummer der Bilddatei.

=head4 Returns

Integer > 0

=head3 width() - Breite

=head4 Synopsis

    $width = $nam->width;

=head4 Description

Liefere die Breitenangabe aus dem Bilddateinamen.

=head4 Returns

Integer > 0

=head3 height() - Höhe

=head4 Synopsis

    $height = $nam->height;

=head4 Description

Liefere die Höhenangabe aus dem Bilddateinamen.

=head4 Returns

Integer > 0

=head3 text() - Text

=head4 Synopsis

    $str = $nam->text;

=head4 Description

Liefere den (optionalen) Text aus dem Bilddateinamen. Ist kein
Text vorhanden, liefere einen Leerstring ('').

=head4 Returns

String

=cut

# -----------------------------------------------------------------------------

sub text {
    shift->{'text'} // '';
}

# -----------------------------------------------------------------------------

=head3 extension() - Extension

=head4 Synopsis

    $extension = $nam->extension;

=head4 Description

Liefere die Extension des Bilddateinamens.

=head4 Returns

String

=head2 Objektmethoden

=head3 asString() - Liefere die Dateinamen

=head4 Synopsis

    $filename = $nam->asString;

=head4 Returns

String

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;
    
    my $filename = sprintf '%06d-%sx%s',$self->number,
        $self->width,$self->height;
    if (my $text = $self->text) {
        $filename .= "-$text";
    }
    $filename .= '.'.$self->extension;

    return $filename;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.113

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
