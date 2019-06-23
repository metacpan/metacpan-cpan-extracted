package Quiq::File::Image;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Hash;
use Quiq::Path;
use Quiq::Image;
use Quiq::Array;
use Image::Size ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::File::Image - Informationen über Bild-Datei

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bild-Datei-Objekt

=head4 Synopsis

    $img = $class->new($path);

=head4 Description

Instantiiere ein Bild-Datei-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$path) = @_;

    if (!-e $path) {
        $class->throw(
             'IMAGE-00001: File not found',
             Path => $path,
        );
    }

    # Objekt instantiieren

    return $class->SUPER::new(
        # Eigenschaften
        path => $path,
        filename => undef,
        basename => undef,
        extension => undef,
        width => undef,
        height => undef,
        type => undef,
        # Properties
        propertyH => Quiq::Hash->new->unlockKeys,
    );
}

# -----------------------------------------------------------------------------

=head2 Eigenschaften

=head3 path() - Datei-Pfad

=head4 Synopsis

    $path = $img->path;

=head4 Description

Liefere den Dateinamen einschl. Pfad der Bild-Datei.

=head3 filename() - Datei-Name ohne Verzeichnisanteil

=head4 Synopsis

    $filename = $img->filename;

=head4 Description

Liefere den Dateinamen ohne Verzeichnisanteil, aber mit Extension,
z.B. '000456.jpg'.

=cut

# -----------------------------------------------------------------------------

sub filename {
    my $self = shift;

    return $self->memoize('filename',sub {
        my ($self,$key) = @_;
        $self->path =~ m|/([^/]+)$|;
        return $1;
    });
}

# -----------------------------------------------------------------------------

=head3 basename() - Datei-Name ohne Verzeichnis und Extension

=head4 Synopsis

    $basename = $img->basename;

=head4 Description

Liefere den Dateinamen ohne Verzeichnis und Extension, z.B. '000456'.

=cut

# -----------------------------------------------------------------------------

sub basename {
    my $self = shift;

    return $self->memoize('basename',sub {
        my ($self,$key) = @_;
        $self->filename =~ m|([^.]+)|;
        return $1;
    });
}

# -----------------------------------------------------------------------------

=head3 extension() - Datei-Extension

=head4 Synopsis

    $ext = $img->extension;

=head4 Description

Liefere die Extentsion der Datei, z.B. 'png'.

=cut

# -----------------------------------------------------------------------------

sub extension {
    my $self = shift;

    return $self->memoize('extension',sub {
        my ($self,$key) = @_;
        return Quiq::Path->extension($self->path);
    });
}

# -----------------------------------------------------------------------------

=head3 mtime() - Letzte Änderung

=head4 Synopsis

    $mtime = $img->mtime;

=head4 Description

Liefere den Zeitpunkt (Unix Epoch), an dem die Bilddatei
das letzte Mal geändert wurde.

=cut

# -----------------------------------------------------------------------------

sub mtime {
    return (stat(shift->path))[9];
}

# -----------------------------------------------------------------------------

=head3 type() - Bild-Typ

=head4 Synopsis

    $type = $img->type;

=head4 Description

Liefere den Datei-Typ des Bildes, z.B. 'jpg'.

=cut

# -----------------------------------------------------------------------------

sub type {
    my $self = shift;

    return $self->memoize('type',sub {
        my ($self,$key) = @_;

        my $type = Quiq::Image->type($self->path);
        if ($type eq 'jpeg') {
            $type = 'jpg';
        }

        return $type;
    });
}

# -----------------------------------------------------------------------------

=head3 width() - Breite

=head4 Synopsis

    $width = $img->width;

=head4 Description

Liefere die Breite des Bildes in Pixeln, z.B. 1920.

=cut

# -----------------------------------------------------------------------------

sub width {
    my $self = shift;

    return $self->memoize('width',sub {
        my ($self,$key) = @_;
        $self->analyzeFile;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head3 height() - Höhe

=head4 Synopsis

    $height = $img->height;

=head4 Description

Liefere die Höhe des Bildes in Pixeln, z.B. 1080.

=cut

# -----------------------------------------------------------------------------

sub height {
    my $self = shift;

    return $self->memoize('height',sub {
        my ($self,$key) = @_;
        $self->analyzeFile;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head3 size() - Breite und Höhe

=head4 Synopsis

    $size = $img->size;
    ($width,$height) = $img->size;

=head4 Description

Liefere die Breite und Höhe des Bildes in Pixeln. Im Skalarkontext
werden die Breite und Höhe in einem String zusammengefasst geliefert:

    'WIDTHxHEIGHT'

=head4 Examples

List-Kontext:

    $img->size;
    =>
    (1920,1080)

Skalar-Kontext:

    $img->size;
    =>
    '1920x1080'

=cut

# -----------------------------------------------------------------------------

sub size {
    my $self = shift;
    my $width = $self->width;
    my $height = $self->height;
    return wantarray? ($width,$height): $width.'x'.$height;
}

# -----------------------------------------------------------------------------

=head3 scaleFactor() - Skalierungsfaktor für andere Breite, Höhe

=head4 Synopsis

    $scale = $img->scaleFactor($width,$height);

=head4 Description

Liefere den Skalierungsfaktor, wenn das Bild auf die Breite $width
und die Höhe $height skaliert werden soll. Werden nicht-proportionale
Werte für $width und $height angegeben, dass also für die Breite
und die Höhe unterschiedliche Skalierungsfakoren berechnet werden,
liefere von beiden den kleineren Wert.

=head4 Example

Das Bild hat die Größe 249 x 249 und soll skaliert werden auf
die Größe 83 x 83:

    $scale = $img->scaleFactor(83,83);
    # 0.333333333333333

=cut

# -----------------------------------------------------------------------------

sub scaleFactor {
    my ($self,$width,$height) = @_;
    return Quiq::Array->min([$width/$self->width,$height/$self->height]);
}

# -----------------------------------------------------------------------------

=head3 aspectRatio() - Seitenverhältnis

=head4 Synopsis

    $aspectRatio = $img->aspectRatio;

=head4 Description

Liefere das Seitenverhältnis des Bildes, z.B. '16:9'.

=cut

# -----------------------------------------------------------------------------

sub aspectRatio {
    my $self = shift;
    return Quiq::Image->aspectRatio($self->width,$self->height);
}

# -----------------------------------------------------------------------------

=head2 Properties

=head3 property() - Liefere Property-Hash

=head4 Synopsis

    $h = $img->property;
    $h = $img->property(\%hash);

=head4 Description

Liefere eine Referenz auf den Property-Hash des Bildes. Der
Property-Hash speichert zusätzliche Eigenschaften des
Bild-Datei-Objektes, die z.B. im Zuge einer Bild-Bearbeitung
verwendet werden.

Der Property-Hash ist ein Quiq::Hash-Objekt, dessen Schlüssel
nicht gelockt sind. Nach der Objekt-Instantiierung ist der
Property-Hash leer.

=head4 Examples

Setze Eigenschaft:

    $img->property->set(sizeFill=>[1440,1080]);

Eigenschaft abfragen:

    ($width,$height) = $img->property->getArray('sizeFill');

=cut

# -----------------------------------------------------------------------------

sub property {
    my $self = shift;
    # @_: \%hash

    if (@_) {
        return $self->{'propertyH'} = shift;
    }

    return $self->{'propertyH'};
}

# -----------------------------------------------------------------------------

=head2 Interne Methoden

=head3 analyzeFile() - Analysiere Bild-Datei

=head4 Synopsis

    $img->analyzeFile;

=head4 Description

Analysiere die Bild-Datei und weise die ermittelten
Eigenschaften an die Attribute des Objektes zu.

=cut

# -----------------------------------------------------------------------------

sub analyzeFile {
    my $self = shift;

    if (!defined $self->get('width')) {
        my ($width,$height) = Image::Size::imgsize($self->path);
        $self->set(width=>$width);
        $self->set(height=>$height);
    }

    return;
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
