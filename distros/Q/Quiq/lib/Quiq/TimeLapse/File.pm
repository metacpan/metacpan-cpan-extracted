package Quiq::TimeLapse::File;
use base qw/Quiq::File::Image/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::TimeLapse::Filename;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TimeLapse::File - Bildsequenz-Datei

=head1 BASE CLASS

L<Quiq::File::Image>

=head1 SYNOPSIS

    # Klasse laden
    use %CLASS;
    
    # Instantiiere Bilddatei-Objekt
    $img = Quiq::TimeLapse::File->new('/my/image/dir/000219-3000x2250-G0080108.jpg');
    
    # Nummer
    $n = $img->number; # 219
    
    # Breite
    $width = $img->width; # 3000
    
    # Höhe
    $height = $img->height; # 2250
    
    # Name
    $name = $img->name; # 'G0080108'
    
    # weitere Methoden siehe Basisklasse

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Bilddatei, die Teil
einer Bildsequenz ist. Der Dateiname hat den Aufbau

    NNNNNN-WIDTHxHEIGHT[-NAME].EXT

Hierbei ist NNNNNN die Bild-Nummer.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bilddatei-Objekt

=head4 Synopsis

    $img = $class->new($file);

=head4 Arguments

=over 4

=item $file

Pfad der Bilddatei.

=back

=head4 Returns

Referenz auf das Bilddatei-Objekt.

=head4 Description

Instantiiere Datei $file als Bilddatei-Objekt und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file) = @_;

    my $nam = Quiq::TimeLapse::Filename->new($file);

    my $self = $class->SUPER::new($file);
    $self->add(
        nam => $nam,
        rangeKey => '',
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

Alle weiteren Methoden befinden sich in der Basisklasse (s. Abschnitt
L<BASE CLASS|"BASE CLASS">).

=head3 number() - Nummer des Bildes

=head4 Synopsis

    $n = $img->number;

=head4 Returns

Integer >= 1

=head4 Description

Liefere die Nummer des Bildes als Zahl. Z.B. 47.

=cut

# -----------------------------------------------------------------------------

sub number {
    return shift->{'nam'}->number;
}

# -----------------------------------------------------------------------------

=head3 width() - Breite des Bildes

=head4 Synopsis

    $width = $img->width;

=head4 Returns

Integer >= 1

=head4 Description

Liefere die Breite des Bildes.

=cut

# -----------------------------------------------------------------------------

sub width {
    my $self = shift;
    return $self->{'nam'}->width || $self->SUPER::width;
}

# -----------------------------------------------------------------------------

=head3 height() - Höhe des Bildes

=head4 Synopsis

    $height = $img->height;

=head4 Returns

Integer >= 1

=head4 Description

Liefere die Höhe des Bildes.

=cut

# -----------------------------------------------------------------------------

sub height {
    my $self = shift;
    return $self->{'nam'}->height || $self->SUPER::height;
}

# -----------------------------------------------------------------------------

=head3 text() - Text des Dateinamens

=head4 Synopsis

    $text = $img->text;

=head4 Returns

String

=head4 Description

Liefere den Text des Dateinamens.

=cut

# -----------------------------------------------------------------------------

sub text {
    return shift->{'nam'}->text;
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
