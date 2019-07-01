package Quiq::TimeLapse::Sequence;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Duration;
use Quiq::Path;
use Quiq::Progress;
use Quiq::ImageMagick;
use File::Temp ();
use Quiq::Option;
use Quiq::FFmpeg;
use Image::Size ();
use Digest::SHA ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TimeLapse::Sequence - Bildsequenz

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

    # Klasse laden
    use %CLASS;
    
    # Instantiiere Sequence-Objekt
    $tsq = Quiq::TimeLapse::Sequence->new(\@images);
    
    # Exportiere Bilddateien in Verzeichnis
    $tsq->export($dir);

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bildsequenz-Objekt

=head4 Synopsis

    $tsq = $class->new(\@images);

=head4 Arguments

=over 4

=item @images

Array von Bilddatei-Objekten

=back

=head4 Returns

Referenz auf das Bildsequenz-Objekt

=head4 Description

Instantiiere Bildsequenz-Objekt aus den Bilddateien \@images und
liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$imageA) = @_;

    return $class->SUPER::new(
        imageA => $imageA,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 count() - Anzahl der Bilder

=head4 Synopsis

    $n = $tsq->count;

=head4 Returns

Integer >= 0

=head4 Description

Liefere die Anzahl der in der Sequenz enthaltenen Bilddateien.

=cut

# -----------------------------------------------------------------------------

sub count {
    my $self = shift;
    return scalar @{$self->{'imageA'}};
}

# -----------------------------------------------------------------------------

=head3 duration() - Dauer der Bildsequenz

=head4 Synopsis

    $duration = $tsq->duration($framerate);

=head4 Returns

String

=head4 Description

Berechne die Dauer der Bildsequenz, wenn sie mit Framerate $framerate
gerendert wird, und liefere das Ergebnis als Zeitdauer in
dem Format C<HhMmS.XXXs> (drei Nachkommastellen).

=cut

# -----------------------------------------------------------------------------

sub duration {
    my ($self,$framerate) = @_;
    return Quiq::Duration->secondsToString($self->count/$framerate,3);
}

# -----------------------------------------------------------------------------

=head3 export() - Exportiere Bildsequenz

=head4 Synopsis

    $tsq->export($destDir);

=head4 Arguments

=over 4

=item $destDir

Pfad des Zielverzeichnisses.

=back

=head4 Returns

nichts

=head4 Description

Exportiere die Bildsequenz nach Verzeichnis $destDir. Existiert
$destDir nicht, wird es erzeugt. Existiert das Verzeichnis, wird
die Bildsequenz angehängt.

=cut

# -----------------------------------------------------------------------------

sub export {
    my ($self,$dir) = @_;

    Quiq::Path->mkdir($dir,-recursive=>1);
    
    my $max = Quiq::Path->maxFileNumber($dir);

    my $pro = Quiq::Progress->new($self->count,
        -show => 1,
    );
    my $i = 0;
    for my $img ($self->images) {
        $i++;
        my $destFile = sprintf '%s/%06d.%s',$dir,$max+$i,$img->type;
        print $pro->msg($i,'%s: i/n x% t/t(t) x/s: %s','link',$destFile);
        Quiq::Path->symlinkRelative($img->path,$destFile);
    }
    print $pro->msg;

    return;
}

# -----------------------------------------------------------------------------

=head3 morph() - Exportiere Bildsequenz mit Zwischenbildern

=head4 Synopsis

    $tsq->morph($n,$destDir);

=head4 Arguments

=over 4

=item $n

Anzahl der Zwischenbilder.

=item $destDir

Pfad des Zielverzeichnisses.

=back

=head4 Returns

nichts

=head4 Description

Exportiere die Bildsequenz nach Verzeichnis $destDir mit jeweils
$n gemorphten Zwischenbildern. Existiert $destDir nicht, wird es
erzeugt. Existiert das Verzeichnis, wird die Bildsequenz
angehängt.

=cut

# -----------------------------------------------------------------------------

sub morph {
    my ($self,$n,$dir) = @_;

    Quiq::Path->mkdir($dir,-recursive=>1);
    
    my $max = Quiq::Path->maxFileNumber($dir);

    $| = 1;
    my $pro = Quiq::Progress->new(($self->count-1)*($n+1)+1,
        -show => 1,
    );

    my $j = 0;
    my $imageA = $self->images;
    for (my $i = 0; $i < @$imageA-1; $i++) {
        my $img1 = $imageA->[$i];
        my $img2 = $imageA->[$i+1];
        my $ext = $img1->type;

        my $tmpDir = File::Temp::tempdir(CLEANUP=>1);
        
        my $cmd = Quiq::ImageMagick->morph($img1,$img2,
            "$tmpDir/%02d.$ext",$n);
        $cmd->execute;

        my @files = Quiq::Path->glob("$tmpDir/*");
        if ($i < @$imageA-2) {
            pop @files;
        }
        for my $srcFile (@files) {
            $j++;
            my $destFile = sprintf '%s/%06d.%s',$dir,$max+$j,$ext;
            print $pro->msg($j,'i/n x% t/t(t) x/s: %s',$destFile);
            Quiq::Path->copy($srcFile,$destFile);
        }
    }
    print $pro->msg;

    return;
}

# -----------------------------------------------------------------------------

=head3 generate() - Erzeuge Video

=head4 Synopsis

    $tsq->generate($file,@opt);

=head4 Arguments

=over 4

=item $file

Die zu erzeugende Video-Datei, z.B. '2018-07-28-anreise.mp4'.

=back

=head4 Options

=over 4

=item -dryRun => $bool (Default: 0)

Zeige Änderungen, führe sie aber nicht aus.

=item -endFrames => $sec (Default: 1)

Dauer der am Ende des Clip hinzugefügten "Ende-Frames" in
Sekunden.  Ist der Wert negativ, wird der Clip auf diese Dauer
verlängert (ist der Clip länger, wird der Default genommen).  Die
End-Frames verlängern den Clip bis zur vollen Sekunde plus $sec-1
Sekunden. D.h. der Wert 1 füllt bis zur nächsten vollen Sekunde
auf. Bei 0 werden keine End-Frames hinzugefügt (was nicht ratsam
ist, da ffmpeg dann am Clip-Ende seltsame Ergebnisse produziert).

=item -framerate => $n (Default: 8)

Anzahl Bilder pro Sekunde.

=item -preset => $preset (Default: 'ultrafast')

Satz an vorgewählten Optionen, für Encoding-Zeit
vs. Kompressionsrate. Schnellstes Encoding: 'ultrafast', beste
Kompression: 'veryslow'. Siehe Quiq::FFmpeg, imagesToVideo().

=item -size => "$width:$height" (Default: undef)

Geometrie des erzeugten Videos.

=item -videoBitrate => $bitrate (Default: 60_000)

Video-Bitrate in kbit/s.

=item -videoFramerate => $n (Default: 24)

Framerate des Video.

=back

=head4 Returns

nichts

=head4 Description

Erzeuge aus der Bildsequenz das Video $file.

=cut

# -----------------------------------------------------------------------------

sub generate {
    my $self = shift;
    my $file = shift;

    # Optionen

    my $dryRun = 0;
    my $endFrames = 1;
    my $framerate = 8;
    my $preset = 'ultrafast',
    my $size = undef;
    my $videoBitrate = 200_000;
    my $videoFramerate = 24;

    Quiq::Option->extract(\@_,
        -dryRun => \$dryRun,
        -endFrames => \$endFrames,
        -framerate => \$framerate,
        -preset => \$preset,
        -size => \$size,
        -videoBitrate => \$videoBitrate,
        -videoFramerate => \$videoFramerate,
    );

    # Prüfe Änderungen an der Sequenz mittels SHA1 Hash. Wenn keine
    # Änderungen vorhanden sind, erzeugen wir den Clip nicht neu.
    
    my $sha1 = $self->sha1($endFrames,$framerate,$preset,$size,$videoBitrate,
        $videoFramerate);
    (my $sha1File = $file) .= '.sha1';
    if (-e $sha1File && -e $file) {
        if ($sha1 eq Quiq::Path->read($sha1File)) {
            return;
        }
    }

    printf "Generating clip: %s\n",$file;
    printf "Clip duration: %s\n",$self->duration($framerate);

    if ($dryRun) {
        return;
    }

    # Vor Neuerzeugung SHA1-Datei löschen
    Quiq::Path->delete($sha1File);

    # Bildsequenz exportieren
    
    my $dir = "/tmp/timelapse$$";
    Quiq::Path->delete($dir);
    $self->export($dir);
    
    if ((my $count = $self->count) && $endFrames) {
        # End-Frames generieren

        my $maxFile = Quiq::Path->maxFilename($dir);
        (my $fmt = $maxFile) =~ s/^(\d+)/%06d/;
        my $maxNumber = $1;

        my $srcFile = "$dir/$maxFile";
        my $destFile = sprintf "%s/$fmt",$dir,$maxNumber+1;

        my ($width,$height) = Image::Size::imgsize($srcFile);

        my $cmd = Quiq::ImageMagick->new;
        $cmd->addCommand('convert');
        $cmd->addElement($srcFile);
        $cmd->addOption(-stroke=>'#ff0000');
        $cmd->addOption(-strokewidth=>16);
        $cmd->addOption(-draw=>sprintf('line 0,0 %s,%s',$width-1,$height-1));
        $cmd->addOption(-draw=>sprintf('line 0,%s %s,0',$height-1,$width-1));
        $cmd->addElement($destFile);
        $cmd->execute;

        # Mehr als eine Sekunde ist ratsam, damit unter kdenlive
        # nachträglich Frames ergänzt werden können, ohne den Clip zu
        # entfernen und wieder hinzufügen zu müssen

        my $duration = $count/$framerate;
    
        if ($endFrames < 0) {
            my $length = abs $endFrames;
            $endFrames = $length > $duration? $length-int($duration): 1;
        }
        my $n = (int($duration)+$endFrames)*$framerate-$count;

        printf "End frames: %d\n",$n;
        for (my $i = 2; $i <= $n+1; $i++) {
            my $link = sprintf $fmt,$maxNumber+$i;
            Quiq::Path->symlink($destFile,"$dir/$link");
        }
    }

    # Video generieren

    my $cmd = Quiq::FFmpeg->imagesToVideo("$dir/*.jpg",$file,
        -framerate => $framerate,
        -preset => $preset,
        -size => $size,
        -videoBitrate => $videoBitrate,
        -videoFramerate => $videoFramerate,
    );
    printf "%s\n",$cmd->command;
    $cmd->execute;

    # SHA1-Datei schreiben
    Quiq::Path->write($sha1File,$sha1);
        
    # Exportverzeichnis löschen
    Quiq::Path->delete($dir);

    return;
}

# -----------------------------------------------------------------------------

=head3 images() - Liste der Bilddatei-Objekte

=head4 Synopsis

    @images|$imageA = $tsq->images;

=head4 Returns

Liste Bilddatei-Objekte. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Bilddatei-Objekte der Sequenz.

=cut

# -----------------------------------------------------------------------------

sub images {
    my $self = shift;
    my $imageA = $self->{'imageA'};
    return wantarray? @$imageA: $imageA;
}

# -----------------------------------------------------------------------------

=head3 sha1() - Hash Digest der Sequenz

=head4 Synopsis

    $sha1 = $tsq->sha1(@keyVal);

=head4 Returns

SHA1 Digest

=head4 Description

Berechne den SHA1 Hash-Wert für die Sequenz und liefere diesen zurück.
Der Hash-Wert wird gebildet über allen Bilddateien, derem Pfad,
deren Größe und Änderungszeitpunkt.

Anhand des SHA1 Hash-Werts läßt sich prüfen, ob eine Änderung an
der Bildsequenz stattgefunden hat und eine teure Operation wie das
(erneute) Rendern eines Video notwendig ist.

=cut

# -----------------------------------------------------------------------------

sub sha1 {
    my $self = shift;
    # @_: @keyVal

    my $text;
    if (@_) {
        $text .= join(',',@_)."\n";
    }
    for my $img (@{$self->{'imageA'}}) {
        my $path = $img->path;
        my ($size,$mtime) = (stat $path)[7,9];
        $text .= sprintf "%s %s %s\n",$path,$mtime,$size;
    };
    
    return Digest::SHA::sha1_hex($text);
}

# -----------------------------------------------------------------------------

=head2 Manipulation

=head3 pick() - Reduziere auf jede n-te Bilddatei

=head4 Synopsis

    $tsq = $tsq->pick($n);

=head4 Returns

Bildsquenz-Objekt (für Chaining)

=head4 Description

Reduziere die Folge der Bilddatei-Objekte auf jedes n-te Element,
d.h. entferne alle anderen

=cut

# -----------------------------------------------------------------------------

sub pick {
    my ($self,$n) = @_;

    my $imageA = $self->{'imageA'};
    
    for (my $i = 0; $i < @$imageA; $i++) {
        splice @$imageA,$i,$n-1;
    } 

    return $self;
}

# -----------------------------------------------------------------------------

=head3 reverse() - Kehre Folge der Bilddatei-Objekt um

=head4 Synopsis

    $tsq = $tsq->reverse;

=head4 Returns

Bildsquenz-Objekt (für Chaining)

=head4 Description

Kehre die Folge der Bilddatei-Objekte um, so dass das erste Bild zum
letzten wird, das zweite zum vorletzten usw.

=cut

# -----------------------------------------------------------------------------

sub reverse {
    my $self = shift;

    @{$self->{'imageA'}} = reverse @{$self->{'imageA'}};

    return $self;
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
