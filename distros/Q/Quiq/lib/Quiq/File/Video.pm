package Quiq::File::Video;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Option;
use Quiq::Ipc;
use Quiq::Formatter;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::File::Video - Informationen über Video-Datei

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Video-Datei-Objekt

=head4 Synopsis

    $vid = $class->new($file,@opt);

=head4 Options

=over 4

=item -verbose => $bool (Default: 1)

Gib das ffprobe-Kommando auf STDOUT aus.

=back

=head4 Description

Instantiiere ein Video-Datei-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file) = @_;

    # Optionen

    my $verbose = 1;

    Quiq::Option->extract(\@_,
        -verbose => \$verbose,
    );

    # Objekt instantiieren

    return $class->SUPER::new(
        file => $file,
        verbose => $verbose,
        width => undef,
        height => undef,
        aspectRatio => undef,
        bitrate => undef,
        framerate => undef,
        duration => undef,
        frames => undef,
    );
}

# -----------------------------------------------------------------------------

=head2 Eigenschaften

=head3 file() - Dateiname

=head4 Synopsis

    $file = $vid->file;

=head4 Description

Liefere den Dateinamen (Pfad) der Video-Datei.

=head3 width() - Breite

=head4 Synopsis

    $width = $vid->width;

=head4 Description

Liefere die Breite des Video in Pixeln, z.B. 1920.

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

    $height = $vid->height;

=head4 Description

Liefere die Höhe des Video in Pixeln, z.B. 1080.

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

    ($width,$height) = $vid->size;

=head4 Description

Liefere die Breite und Höhe des Video in Pixeln, z.B. (1920,1080).

=cut

# -----------------------------------------------------------------------------

sub size {
    my $self = shift;
    return ($self->width,$self->height);
}

# -----------------------------------------------------------------------------

=head3 aspectRatio() - Seitenverhältnis

=head4 Synopsis

    $aspectRatio = $vid->aspectRatio;

=head4 Description

Liefere das Seitenverhältnis des Video, z.B. '16:9'.

=cut

# -----------------------------------------------------------------------------

sub aspectRatio {
    my $self = shift;

    my $width = $self->width;
    my $height = $self->height;

    if ($width/16*9 == $height) {
         return '16:9';
    }
    elsif ($width/4*3 == $height) {
         return '4:3';
    }

    return $width/$height;
}

# -----------------------------------------------------------------------------

=head3 bitrate() - Bitrate

=head4 Synopsis

    $bitrate = $vid->bitrate;

=head4 Description

Liefere die Bitrate des Video in Kilobit (kb/s), z.B. 30213.

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

    $duration = $vid->duration;

=head4 Description

Liefere die Dauer des Video in Sekunden (millisekundengenau),
z.B. 8.417.

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

=head3 frames() - Anzahl Frames

=head4 Synopsis

    $frames = $vid->frames;

=head4 Description

Liefere die Anzahl der Frames des Video, z.B. 101.

=cut

# -----------------------------------------------------------------------------

sub frames {
    my $self = shift;

    return $self->memoize('frames',sub {
        my ($self,$key) = @_;
        $self->analyzeFile;
        return $self->get($key);
    });
}

# -----------------------------------------------------------------------------

=head2 Interne Methoden

=head3 analyzeFile() - Analysiere Video-Datei

=head4 Synopsis

    $vid->analyzeFile;

=head4 Description

Analysiere die Video-Datei mit ffprobe und weise die ermittelten
Eigenschaften an die Attribute des Objektes zu.

=cut

# -----------------------------------------------------------------------------

sub analyzeFile {
    my $self = shift;

    if (!defined $self->get('width')) {
        my $file = $self->file;
        $file =~ s/([\$"])/\\$1/g;

        # Dateiinformation in XML gewinnen

        my $cmd = q|ffprobe -loglevel error -print_format xml|.
            qq| -show_streams -select_streams v:0 '$file'|;

        if ($self->verbose) {
            print "$cmd\n";
        }

        my ($xml) = Quiq::Ipc->filter($cmd);

        # Breite, Höhe

        my ($width) = $xml =~ /\bwidth="(\d+)"/;
        my ($height) = $xml =~ /\bheight="(\d+)"/;

        if (!$width || !$height) {
            $self->throw;
        }

        $self->set(width=>$width);
        $self->set(height=>$height);

        # Bitrate in kb

        my ($bitrate) = $xml =~ /\bbit_rate="(\d+)"/;
        $self->set(bitrate=>int $bitrate/1000); # ffmpeg rechnet offenbar so

        # Framerate
    
        # MEMO: manchmal gibt es das Feld frame_rate nicht, sondern
        # nur die r_frame_rate und avg_frame_rate.

        my ($framerate) = $xml =~ /\b(?:avg_)?frame_rate="(.+?)"/;
        if ($framerate =~ m|/|) {
            my ($x,$y) = split m|/|,$framerate;
            $framerate = Quiq::Formatter->normalizeNumber(
                sprintf '%.2f',$x/$y);
        }
        $self->set(framerate=>$framerate);

        # Dauer (millisekundengenau)

        my ($duration) = $xml =~ /\bduration="([\d.]+)"/;
        $duration = Quiq::Formatter->normalizeNumber(
            sprintf '%.3f',$duration);
        $self->set(duration=>$duration);

        # Anzahl Frames

        my ($frames) = $xml =~ /\bnb_frames="(\d+)"/;
        $self->set(frames=>$frames);
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
