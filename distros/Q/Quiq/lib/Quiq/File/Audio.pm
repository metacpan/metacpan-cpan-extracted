package Quiq::File::Audio;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Quiq::Shell;
use Quiq::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::File::Audio - Informationen über Audio-Datei

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Audio-Datei-Objekt

=head4 Synopsis

    $aud = $class->new($file);

=head4 Description

Instantiiere ein Audio-Datei-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file) = @_;

    return $class->SUPER::new(
        file => $file,
        artist => undef,
        title => undef,
        duration => undef,
        bitrate => undef,
        extension => undef,
    );
}

# -----------------------------------------------------------------------------

=head2 Meta-Information

=head3 artist() - Künstler

=head4 Synopsis

    $artist = $aud->artist;

=head4 Description

Liefere den Künstler der Audio-Datei.

=head4 See Also

L<extractMetaData|"extractMetaData() - Ermittele Künstler und Titel">()

=cut

# -----------------------------------------------------------------------------

sub artist {
    my $self = shift;

    return $self->memoize('artist',sub {
        my ($self,$key) = @_;
        $self->extractMetaData;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head3 title() - Titel

=head4 Synopsis

    $title = $aud->title;

=head4 Description

Liefere den Titel der Audio-Datei.

=head4 See Also

L<extractMetaData|"extractMetaData() - Ermittele Künstler und Titel">()

=cut

# -----------------------------------------------------------------------------

sub title {
    my $self = shift;

    return $self->memoize('title',sub {
        my ($self,$key) = @_;
        $self->extractMetaData;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 bitrate() - Bitrate

=head4 Synopsis

    $bitrate = $aud->bitrate;

=head4 Description

Liefere die Bitrate der Audion-Datei (z.Zt. als Zeichenkette).

=cut

# -----------------------------------------------------------------------------

sub bitrate {
    my $self = shift;

    return $self->memoize('bitrate',sub {
        my ($self,$key) = @_;
        $self->analyzeFile;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head3 duration() - Dauer

=head4 Synopsis

    $duration = $aud->duration;

=head4 Description

Liefere die Länge (Dauer) der Audio-Datei in Sekunden
(ggf. mit Nachkommastellen).

=cut

# -----------------------------------------------------------------------------

sub duration {
    my $self = shift;

    return $self->memoize('duration',sub {
        my ($self,$key) = @_;
        $self->analyzeFile;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head3 extension() - Extension

=head4 Synopsis

    $ext = $aud->extension;

=head4 Description

Liefere die Extension der Audio-Datei.

=head4 See Also

L<extractMetaData|"extractMetaData() - Ermittele Künstler und Titel">()

=cut

# -----------------------------------------------------------------------------

sub extension {
    my $self = shift;

    return $self->memoize('extension',sub {
        my ($self,$key) = @_;
        $self->extractMetaData;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head3 file() - Dateiname

=head4 Synopsis

    $file = $aud->file;

=head4 Description

Liefere den Dateinamen (Pfad) der Audio-Datei.

=head2 Interne Methoden

=head3 analyzeFile() - Analysiere Audio-Datei

=head4 Synopsis

    $aud->analyzeFile;

=head4 Description

Analysiere die Audio-Datei mit ffprobe und weise die ermittelten
Eigenschaften an die betreffenden Attribute des Objektes zu.

=cut

# -----------------------------------------------------------------------------

sub analyzeFile {
    my $self = shift;

    if (!defined $self->get('duration')) {
        my $file = $self->file;
        $file =~ s/([\$"])/\\$1/g;
        my $cmd = sprintf 'ffprobe "%s"',$file;
        my $outp = Quiq::Shell->exec($cmd,
            -capture => 'stdout+stderr',
            -sloppy => 1,
        );

        # Duration

        my $duration = 0;
        $outp =~ /\bDuration:\s+([\d:.]+)/i;
        if ($1) {
            my ($h,$m,$s) = split /:/,$1;
            $duration = $h*3600+$m*60+$s;
        }
        $self->set(duration=>$duration);

        # Bitrate

        my $bitrate = '';
        $outp =~ /\bBitrate:\s*(.*)/i;
        if (defined $1) {
            $bitrate = $1;
        }
        $self->set(bitrate=>$bitrate);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 extractMetaData() - Ermittele Künstler und Titel

=head4 Synopsis

    $aud->extractMetaData;

=head4 Description

Zerlege den Dateiname in die Komponenten <Artist> und <Title>
und weise sie den betreffenden Objektattributen zu.

Es wird vorausgesetzt, dass der Dateiname folgenden Aufbau hat:

    <Path>/<Artist> - <Title>.<Extension>

Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub extractMetaData {
    my $self = shift;

    my (undef,undef,$basename,$ext) = Quiq::Path->split($self->file);
    my ($artist,$title) = split / - /,$basename;
    $self->set(
        artist => $artist,
        title => $title,
        extension => $ext,
    );

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
