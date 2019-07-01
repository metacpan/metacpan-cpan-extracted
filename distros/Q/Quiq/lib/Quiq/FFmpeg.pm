package Quiq::FFmpeg;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::File::Video;
use POSIX ();
use Quiq::Option;
use Quiq::Duration;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::FFmpeg - Konstruiere eine FFmpeg-Kommandozeile

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

FFmpg Online-Dokumentation:
L<https://www.ffmpeg.org/ffmpeg-all.html>

Ein Objekt der Klasse repräsentiert eine ffmpeg-Kommandozeile.
Die Klasse verfügt einerseits über I<elementare> (Objekt-)Methoden,
um eine solche Kommandozeile sukzessive aus Eingabe- und
Ausgabe-Dateien, Optionen, Filtern usw. zu konstruieren und
andererseits I<höhere> (Klassen-)Methoden, die eine vollständige
Kommandozeile zur Erfüllung eines bestimmten Zwecks unter
Rückgriff auf die elementaren Methoden erstellen. Die höheren
Methoden Methoden befinden sich im Abschnitt L<Klassenmethoden (vollständige Kommandozeilen)|"Klassenmethoden (vollständige Kommandozeilen)">.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $cmd = $class->new;
    $cmd = $class->new($str);

=head4 Description

Instantiiere ein FFmpeg-Kommando-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$str) = @_;

    return $class->SUPER::new(
        cmd => $str // '',
        inputA => [],
        inputObjectA => [],
        outputA => [],
        outName => undef,
        outWidth => undef,
        outHeight => undef,
        outStart => undef,
        outStop => undef,
    );
}
    

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 command() - Kommandozeile als Zeichenkette

=head4 Synopsis

    $str = $cmd->command;

=head4 Description

Liefere das Kommando als Zeichenkette.

=cut

# -----------------------------------------------------------------------------

sub command {
    return shift->{'cmd'};
}
    

# -----------------------------------------------------------------------------

=head3 input() - Eingabe-Datei als Objekt

=head4 Synopsis

    $fil = $cmd->input($i);

=head4 Description

Instantiiere Eingabe-Datei $i als Quiq::File-Objekt und liefere
dieses zurück. Das Objekt wird gecached.

=cut

# -----------------------------------------------------------------------------

sub input {
    my ($self,$i) = @_;

    my $fil = $self->inputObjectA->[$i];
    if (!$fil) {
        if (my $input = $self->inputA->[$i]) {
            $fil = Quiq::File::Video->new($input);
            $self->inputObjectA->[$i] = $fil; # cachen
        }
    }

    return $fil;
}
    

# -----------------------------------------------------------------------------

=head3 suffix() - Suffix Ausgabe-Datei

=head4 Synopsis

    $str = $cmd->suffix;

=head4 Description

Liefere den Suffix für eine Ausgabedatei. Der Suffix ist eine
Zeichenkette der Form

    NAME-WIDTH-HEIGHT-START-STOP

wobei Komponenten fehlen können, die nicht definiert sind.

=cut

# -----------------------------------------------------------------------------

sub suffix {
    my $self = shift;

    my @suffix;

    my ($outName,$outWidth,$outHeight,$outStart,$outStop) =
        $self->get(qw/outName outWidth outHeight outStart outStop/);
    
    # name
    
    if ($outName) {
        push @suffix,$outName;
    }

    # size
    
    if ($outWidth && $outHeight) {
        push @suffix,sprintf('%04dx%04d',$outWidth,$outHeight);
    }

    # start, stop

    if (defined($outStart) && $outStop) {
        push @suffix,sprintf '%03d-%03d',POSIX::floor($outStart),
            POSIX::ceil($outStop);
    }
    
    return join '-',@suffix;
}
    

# -----------------------------------------------------------------------------

=head2 Kommandozeile konstruieren

=head3 addOption() - Füge Option hinzu

=head4 Synopsis

    $cmd->addOption($opt);
    $cmd->addOption($opt=>$val);

=head4 Description

Ergänze die Kommandozeile um die Option $opt und (optional) den
Wert $val. Die Methode liefert keinen Wert zurück.

=head4 Examples

Option ohne Wert:

    $cmd->addOption('-y');
    =>
    -y

Option mit Wert:

    $cmd->addOption(-i=>'video/GOPR1409.mp4');
    =>
    -i 'video/GOPR1409.mp4'

=cut

# -----------------------------------------------------------------------------

sub addOption {
    my $self = shift;
    my $opt = shift;
    # @_: $val

    my $ref = $self->getRef('cmd');
    my $val;
    if (@_) {
        $val = shift;
        if (!defined($val) || $val eq '') {
            # Keine Option hinzufügen, wenn Wert-Argument,
            # angegeben, dieses aber undef oder '' ist
            return;
        }
    }

    if ($$ref) {
        $$ref .= ' ';
    }
    $$ref .= $opt;

    if (defined $val) {
        $$ref .= ' ';
        if ($val =~ /^([0-9.]+|[A-Za-z0-9:]+)$/) {
            $$ref .= $val;
        }
        else {
            $$ref .= "'$val'";
        }
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 addInput() - Füge Input-Option hinzu

=head4 Synopsis

    $cmd->addInput($input);

=head4 Description

Ergänze das Kommando um Input $input, sofern $input einen Wert hat.
Die Methode liefert keinen Wert zurück.

=head4 Examples

Dateiname:

    $cmd->addInput('video/GOPR1409.mp4');
    =>
    -i 'video/GOPR1409.mp4'

Muster:

    $cmd->addInput('img/*.jpg');
    =>
    -i 'img/*.jpg'

Undefiniert:

    $cmd->addInput(undef);
    =>

=cut

# -----------------------------------------------------------------------------

sub addInput {
    my ($self,$input) = @_;

    if ($input) {
        $self->addOption(-i=>$input);
        $self->push(inputA=>$input);
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 addFilter() - Füge Filter-Option hinzu

=head4 Synopsis

    $cmd->addFilter($opt,\@filter,$sep);

=head4 Description

Ergänze das Kommando um Filter-Option $opt mit den Filtern @filter
und dem Trenner $sep (Komma oder Semikolon).

=head4 Examples

Video Filter-Chain:

    $cmd->addFilter(-vf=>['crop=1440:1080','scale=720*a:720']);
    =>
    -vf 'crop=1440:1080,scale=720*a:720'

=cut

# -----------------------------------------------------------------------------

sub addFilter {
    my ($self,$opt,$filterA,$sep) = @_;

    if (my $val = join($sep,@$filterA)) {
        $self->addOption($opt=>$val);
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 addStartStop() - Füge Optionen für Zeitbereich hinzu

=head4 Synopsis

    $cmd->addStartStop($start,$stop);

=head4 Description

Ergänze das Kommando um Optionen, die den Zeitbereich auf
den Bereich $start und $stop eingrenzen.

=head4 Examples

Nur Start-Zeitpunkt:

    $cmd->addStartStop(5.5);
    =>
    -ss 5.5

Nur Ende-Zeitpunkt:

    $cmd->addStartStop(undef,20.5);
    =>
    -t 20.5

Start- und Ende-Zeitpunkt:

    $cmd->addStartStop(5.5,20.5);
    =>
    -ss 5.5 -t 20.5

=cut

# -----------------------------------------------------------------------------

sub addStartStop {
    my ($self,$start,$stop) = @_;

    if ($start) {
        $self->addOption(-ss=>$start);
    }
    
    $start ||= 0;
    if ($stop && $stop > $start) {
        $self->addOption(-t=>$stop-$start);
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 addBitrate() - Füge Bitrate-Option hinzu

=head4 Synopsis

    $cmd->addBitrate($bitrate);

=head4 Description

Ergänze das Kommando um eine allgemeine Bitrate-Option mit
Suffix 'k' (= kb/s). Ist die Bitrate 0, '' oder undef, wird
die Option nicht hinzugefügt.

=head4 Examples

Bitrate von 10000k:

    $cmd->addBitrate(10000);
    =>
    -b 10000k

=cut

# -----------------------------------------------------------------------------

sub addBitrate {
    my ($self,$bitrate) = @_;

    if ($bitrate) {
        $self->addOption(-b=>$bitrate.'k');
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 addOutput() - Füge Output-Argument hinzu

=head4 Synopsis

    $cmd->addOutput($output);

=head4 Description

Ergänze das Kommando um Output $output.
Die Methode liefert keinen Wert zurück.

=head4 Examples

Dateiname:

    $cmd->addOutput('video/GOPR1409.mp4');
    =>
    'video/GOPR1409.mp4'

Muster:

    $cmd->addOutput('img/%06d.jpg');
    =>
    'img/%06d.jpg'

=cut

# -----------------------------------------------------------------------------

sub addOutput {
    my ($self,$out) = @_;

    if (!defined $out || $out eq '') {
        # Dateiname generieren

        my $inputA = $self->get('inputA');
        my ($path,$ext) = $inputA->[0] =~ /(.+?)\.([^.]+)$/;
        $out = sprintf '%s-%s.%s',$path,$self->suffix,$ext;
    }
    else {
        # Suffix einsetzen
        $out =~ s/%S/$self->suffix/e;
    }

    my $ref = $self->getRef('cmd');
    if ($$ref) {
        $$ref .= ' ';
    }
    $$ref .= qq|'$out'|;
    
    $self->push(outputA=>$out);
       
    return;
}

# -----------------------------------------------------------------------------

=head3 addString() - Füge Zeichenkette am Ende hinzu

=head4 Synopsis

    $cmd->addString($str);

=head4 Description

Füge Zeichenkette $str am Ende der Kommandozeile hinzu, mit einem
Leerzeichen als Trenner.

=head4 Example

Kommando nach Objekt-Instantiierung:

    $cmd->addString('ffprobe');
    =>
    ffprobe

=cut

# -----------------------------------------------------------------------------

sub addString {
    my ($self,$str) = @_;

    my $ref = $self->getRef('cmd');
    if ($$ref) {
        $$ref .= ' ';
    }
    $$ref .= $str;
    
    return;
}

# -----------------------------------------------------------------------------

=head3 prependString() - Füge Zeichenkette am Anfang hinzu

=head4 Synopsis

    $cmd->prependString($str);

=head4 Description

Füge Zeichenkette $str am Beginn der Kommandozeile hinzu.
Ein Leerzeichen wird automatisch hinzugefügt.

=head4 Example

Kommando voranstellen:

    $cmd->prependString('ffplay -autoexit');
    =>
    ffplay -autoexit ...

=cut

# -----------------------------------------------------------------------------

sub prependString {
    my ($self,$str) = @_;

    my $ref = $self->getRef('cmd');
    if ($$ref) {
        $$ref = ' '.$$ref;
    }
    $$ref = $str.$$ref;
    
    return;
}

# -----------------------------------------------------------------------------

=head2 Filter

=head3 cropFilter() - Liefere Crop-Filter

=head4 Synopsis

    $str = $cmd->cropFilter($width,$height);
    $str = $cmd->cropFilter($width,$height,$xOffset,$yOffset);

=head4 Description

Erzeuge eine Crop-Filter-Spezifikation für die angegebenen
Argumente und liefere diese zurück.

=head4 Examples

Nur Breite und Höhe:

    $cmd->cropFilter(1280,720);
    =>
    'crop=1280:720'

Breite, Höhe, X-Offset, Y-Offset:

    $cmd->cropFilter(1280,720,240,0);
    =>
    'crop=1280:720:240:0'

=cut

# -----------------------------------------------------------------------------

sub cropFilter {
    my $self = shift;
    my $width = shift;
    my $height = shift;
    # @_: $xOffset,$yOffset

    my $str = "crop=$width:$height";
    if (@_) {
        my $xOffset = shift || 0;
        my $yOffset = shift || 0;
        $str .= ":$xOffset:$yOffset";
    }

    return $str;
}
    

# -----------------------------------------------------------------------------

=head3 scaleFilter() - Liefere Scale-Filter

=head4 Synopsis

    $str = $cmd->scaleFilter($width,$height);
    $str = $cmd->scaleFilter("$width:$height");

=head4 Description

Erzeuge eine Crop-Filter-Spezifikation für die angegebenen
Argumente und liefere diese zurück.

Sind die Argumente undefiniert, wird eine leere Liste geliefert.

=head4 Examples

Breite und Höhe als getrennte Argumente:

    $cmd->scaleFilter(1280,720);
    =>
    'scale=1280:720'

Breite und Höhe in einem Argument:

    $cmd->scaleFilter('1280:720');
    =>
    'scale=1280:720'

Undefiniertes Argument:

    @filter = $cmd->scaleFilter(undef);
    =>
    ()

=cut

# -----------------------------------------------------------------------------

sub scaleFilter {
    my $self = shift;
    # @_: $width,$height -or- "$width,$height"

    my $size;
    if (@_ == 1) {
        $size = shift;
    }
    else {
        if (defined(my $width = shift) && defined(my $height = shift)) {
            $size = "$width:$height";
        }
    }

    if (!defined($size)) {
        return ();
    }

    return "scale=$size";
}
    

# -----------------------------------------------------------------------------

=head3 fpsFilter() - Liefere Fps-Filter

=head4 Synopsis

    $str = $cmd->fpsFilter($fps);

=head4 Description

Erzeuge eine Fps-Filter-Spezifikation und liefere diese zurück.
Ist das Argument undef, liefere eine leere Liste.

=head4 Examples

Argument:

    $cmd->fpsFilter(24);
    =>
    'fps=24'

Undefiniertes Argument:

    @filter = $cmd->fpsFilter(undef);
    =>
    ()

=cut

# -----------------------------------------------------------------------------

sub fpsFilter {
    my ($self,$fps) = @_;
    return !defined $fps? (): "fps=$fps";
}
    

# -----------------------------------------------------------------------------

=head3 framestepFilter() - Liefere Framestep-Filter

=head4 Synopsis

    $str = $cmd->framestepFilter($fps);

=head4 Description

Erzeuge eine Framestep-Filter-Spezifikation und liefere diese zurück.
Ist das Argument undef, liefere eine leere Liste.

=head4 Examples

Argument:

    $cmd->framestepFilter(4);
    =>
    'framestep=4'

Undefiniertes Argument:

    @filter = $cmd->framestepFilter(undef);
    =>
    ()

=cut

# -----------------------------------------------------------------------------

sub framestepFilter {
    my ($self,$framestep) = @_;

    if (!defined($framestep) || $framestep == 1) {
        return ();
    }
    
    return "framestep=$framestep";
}
    

# -----------------------------------------------------------------------------

=head2 Ausgabe-Datei-Eigenschaften (Getter/Setter)

=head3 outName() - Setze/Liefere Bezeichnung Ausgabe-Datei

=head4 Synopsis

    $cmd->outName($name);
    $name = $cmd->outName;

=head4 Description

Setze oder liefere die Bezeichnung für die Ausgabe-Datei.
Die Angabe wird für den Suffix der Ausgabe-Datei genutzt.

=head3 outSize() - Setze/Liefere Breite und Höhe Video-Ausgabe

=head4 Synopsis

    $cmd->outSize($width,$height);
    ($width,$height) = $cmd->outSize;

=head4 Description

Setze oder liefere die Höhe und Breite der Video-Ausgabe.
Die Angabe wird für den Suffix der Video-Ausgabe-Datei genutzt.

=cut

# -----------------------------------------------------------------------------

sub outSize {
    my $self = shift;
    # @_: $width,$height

    if (@_) {
        $self->{'outWidth'} = shift;
        $self->{'outHeight'} = shift;
    }

    return ($self->{'outWidth'},$self->{'outHeight'});
}
    

# -----------------------------------------------------------------------------

=head3 outStart() - Setze/Liefere Start-Zeitpunkt

=head4 Synopsis

    $cmd->outStart($s);
    $s = $cmd->outStart;

=head4 Description

Setze oder liefere den Start-Zeitpunkt der Ausgabe.
Die Angabe wird für den Suffix der Ausgabe-Datei genutzt.

=head3 outStop() - Setze/Liefere Stop-Zeitpunkt

=head4 Synopsis

    $cmd->outStop($s);
    $s = $cmd->outStop;

=head4 Description

Setze oder liefere den Stop-Zeitpunkt der Ausgabe.
Die Angabe wird für den Suffix der Ausgabe-Datei genutzt.

=head2 Klassenmethoden (vollständige Kommandozeilen)

=head3 imagesToVideo() - Füge Bild-Sequenz zu einem Video zusammen

=head4 Synopsis

    $cmd = $class->imagesToVideo($pattern,$output,@opt);

=head4 Arguments

=over 4

=item $pattern

Pfad-Muster der Bilder. Enthält das Pfad-Muster einen Stern (*),
wird C<-pattern_type glob> gewählt.

Beispiele:

    'img/%06d.jpg' => -i 'img/%06d.jpg'
    'img/*.jpg'    => -pattern_type glob -i 'img/*.jpg'

=item $output

Name der generierten Video-Datei.

=back

=head4 Options

=over 4

=item -audio => $file (Default: undef)

Erzeuge einen Audio-Stream aus Audio-Datei $file.

=item -duration => $duration (Default: undef)

Beende die Ausgabe, wenn die Dauer $duration erreicht ist.

=item -framerate => $n (Default: 8)

Anzahl Bilder pro Sekunde.

=item -loop => $bool (Default: 0)

Wiederhole die Bildserie zyklisch.

=item -play => 0|1|2 (Default: 0)

Zeige das generierte Video im Player an, statt es in einer Datei
zu speichern. Bei -play=>2 bleibt das Fenster des Players
offen, bis es per Hand geschlossen wird.

=item -preset => $preset (Default: undef)

Satz an vorgewählten Optionen, für Encoding-Zeit
vs. Kompressionsrate. Mögliche Werte: ultrafast, superfast,
veryfast, faster, fast, medium, slow, slower, veryslow. Siehe
L<https://trac.ffmpeg.org/wiki/Encode/H.264>.

=item -size => "$width:$height" (Default: undef)

Breite und Höhe des generierten Video. Ohne Angabe nimmt
ffmpeg die Größe der Bilder.

=item -videoBitrate => $bitrate (Default: 60_000)

Video-Bitrate in kbit/s.

=item -videoFilter => $filter

Optionale Filterangabe. Z.B. -videoFilter => 'lutyuv=y=val*1.4,hue=s=10'

=item -videoFramerate => $n (Default: 24)

Framerate des Video.

=back

=head4 Description

Generiere ein ffmpeg-Kommando zum Zusammenfügen der Bilder
$pattern zu Video $output und liefere dieses Kommando zurück.

=cut

# -----------------------------------------------------------------------------

sub imagesToVideo {
    my $class = shift;
    # @_: $pattern,$output,@opt

    # Optionen und Argumente

    my $audio = undef;
    my $duration = undef,
    my $framerate = 8;
    my $loop = 0;
    my $play = 0;
    my $preset = undef;
    my $size = undef;
    my $videoBitrate = 60_000;
    my $videoFilter = undef;
    my $videoFramerate = 24;

    Quiq::Option->extract(\@_,
        -audio => \$audio,
        -duration => \$duration,
        -framerate => \$framerate,
        -loop => \$loop,
        -play => \$play,
        -preset => \$preset,
        -size => \$size,
        -videoBitrate => \$videoBitrate,
        -videoFilter => \$videoFilter,
        -videoFramerate => \$videoFramerate,
    );
    if (@_ == 0 || @_ > 2) {
        $class->throw('Usage: $ffm->imagesToVideo($input,$output,@opt)');
    }
    my $pattern = shift;
    my $output = shift;

    # Operation ausführen

    # * Command-Objekt instantiieren    
    my $self = $class->new('ffmpeg -y');
    
    # * Input

    if ($loop) {
        $self->addOption(-loop=>$loop);
    }
    $self->addOption(-framerate=>$framerate);
    $self->addOption(-f=>'image2');
    if ($pattern =~ /\*/) {
        $self->addOption(-pattern_type=>'glob');
    }
    $self->addInput($pattern);

    if ($audio) {
        $self->addInput($audio);
    }
    
    # * Filter

    my @filter;

    # ** fps
    push @filter,$self->fpsFilter($videoFramerate);

    # ** scale

    push @filter,$self->scaleFilter($size);
    if ($play && !$size) {
        push @filter,$self->scaleFilter('720*a',720);
    }

    # ** YUV color space (laut ffmpeg-Doku aus Kompatibilitätsgründen nötig)
    push @filter,'format=yuv420p';

    # ** Optionale Video-Filter

    if ($videoFilter) {
        push @filter,$videoFilter;
    }

    $self->addFilter(-vf=>\@filter,',');

    # * Output-Options

    if (defined $duration) {
        $self->addOption(-t=>$duration);
    }
    elsif ($audio) {
        $self->addOption('-shortest');
    }

    if (defined $videoBitrate) {
        $self->addOption('-b:v'=>$videoBitrate.'k');
    }
    if (defined $preset) {
        $self->addOption(-preset=>$preset);
    }

    # * Output

    if ($play) {
        $self->addOption(-f=>'avi');
        if ($play == 1) {
            $self->addString('- 2>/dev/null | ffplay -autoexit - 2>/dev/null');
        }
        else {
            $self->addString('- 2>/dev/null | ffplay - 2>/dev/null');
        }
    }
    else {
        $self->addOutput($output);
    }
             
    return $self;
}

# -----------------------------------------------------------------------------

=head3 videoToImages() - Extrahiere Bild-Sequenz (Frames) aus Video

=head4 Synopsis

    $cmd = $ffm->videoToImages($input,$dir,@opt);

=head4 Options

=over 4

=item -aspectRatio => '16:9'|'4:3' (Default: undef)

Gewünschtes Seitenverhältnis der Bilder. Hat das Video ein
abweichendes Seitenverhältnis, wird ein entsprechender Crop-Filter
aufgesetzt.

=item -framestep => $n (Default: 1)

Extrahiere jeden $n-ten Frame.

=item -pixelFormat=FMT (Default: 'yuvj422p')

Pixel-Format des erzeugten Bildes. Laut Aussage im Netz ist yuvj422p
das Standard-Pixel-Format für jpeg-Dateien. Wird das Pixel-Format
hier nicht geändert, erzeugt ffmpeg die Bilder in Pixelformat
yuvj420p, was Probleme beim Zusammenfügen mit Bildern einer
Kamera zu einem Film macht.

=item -quality => $n (Default: 2)

Qualität der generierten jpg-Bilddateien. Wertebereich: 2-31, mit
2 als bester und 31 als schlechtester Qualität.

=item -start => $s (Default: 0)

Zeitpunkt in Sekunden (ggf. mit Nachkommastellen) vom Beginn
des Video, an dem das Extrahieren der Frames beginnt.

=item -stop => $s (Default: undef)

Zeitpunkt in Sekunden (ggf. mit Nachkommastellen) vom Beginn
des Video, an dem das Extrahieren der Frames endet.

=back

=head4 Description

Generiere ein ffmpeg-Kommando, das die Frames aus dem Video $input
extrahiert und im Verzeichnis $dir speichert. Die Bilder haben
das Format 'jpg'. Der Name der Dateien ist NNNNNN.jpg, von 1 an
lückenlos aufsteigend.

=head4 Examples

Ohne Optionen:

    $ffm->videoToImages('video.mp4','img');
    =>
    ffmpeg -y -loglevel error -stats
        -i 'video.mp4'
        -qscale:v 2
        'img/%06d.jpg'

Video-Seitenverhältnis 16:9 zu Bild-Seitenverhältnis 4:3 wandeln:

    $ffm->videoToImages('video.mp4','img',
        -aspectRatio => '4:3',
    );
    =>
    ffmpeg -y -loglevel error -stats
        -i 'video.mp4'
        -vf 'crop=ih/3*4:ih'
        -qscale:v 2
        'img/%06d.jpg'

Alle Optionen:

    $ffm->videoToImages('video.mp4','img',
        -aspectRatio => '4:3',
        -framestep => 6,
        -start => 3,
        -stop => 10,
    );
    =>
    ffmpeg -y -loglevel error -stats
        -i 'video.mp4'
        -vf 'framestep=6,crop=ih/3*4:ih'
        -ss 3 -t 7
        -qscale:v 2
        'img/%06d.jpg'

=cut

# -----------------------------------------------------------------------------

sub videoToImages {
    my $class = shift;
    # @_: $input,$dir,@opt
    
    # Optionen und Argumente

    my $aspectRatio = undef;
    my $framestep = 1;
    my $pixelFormat = 'yuvj422p';
    my $quality = 2;
    my $start = 0;
    my $stop = undef;
    
    Quiq::Option->extract(\@_,
        -aspectRatio => \$aspectRatio,
        -framestep => \$framestep,
        -pixelFormat => \$pixelFormat,
        -quality => \$quality,
        -start => \$start,
        -stop => \$stop,
    );
    if (@_ == 0 || @_ > 2) {
        $class->throw('Usage: $ffm->videoToImages($input,$dir,@opt)');
    }
    my $input = shift;
    my $dir = shift;

    # Operation ausführen

    # * Command-Objekt instantiieren    
    my $self = $class->new;
    
    # * Input
    $self->addInput($input);

    # * Filter
    
    my @filter;

    # ** framestep

    push @filter,$self->framestepFilter($framestep);

    if ($aspectRatio) {
        if ($aspectRatio eq '4:3') {
            push @filter,$self->cropFilter('ih/3*4','ih');
        }
        elsif ($aspectRatio eq '16:9') {
            push @filter,$self->cropFilter('iw','iw/16*9');
        }
        else {
            $self->throw;
        }    
    }

    $self->addFilter(-vf=>\@filter,',');

    # Output-Optionen
    
    $self->addStartStop($start,$stop);
    $self->addOption('-qscale:v'=>$quality);
    $self->addOption(-pix_fmt=>$pixelFormat);

    # * Output

    $self->prependString('ffmpeg -y');
    $self->addOutput("$dir/%06d.jpg");

    return $self;
}

# -----------------------------------------------------------------------------

=head3 extract() - Extrahiere Abschnitt aus Audio- oder Video-Datei

=head4 Synopsis

    $cmd = $class->extract($input,$output,@opt);

=head4 Arguments

=over 4

=item $input

Eingabe-Datei.

=item $output

Ausgabe-Datei.

=back

=head4 Options

=over 4

=item -name => $str (Default: undef)

Füge dem Dateinamen die Bezeichnung $str hinzu.

=item -play => 0|1|2 (Default: 0)

Extrahiere den Ausschnitt nicht, sondern zeige ihn an. 1=Exit am Ende,
2=Fenster offen lassen (zu erneuten Positionen).

=item -start => $s (Default: 0)

Start-Position in einem Format, das die Klasse Quiq::Duration
akzeptiert.

=item -stop => $s (Default: undef)

Ende-Position in einem Format, das die Klasse Quiq::Duration
akzeptiert.

=back

=head4 Description

Extrahiere von Position $start bis Position $stop einen Teil
aus der Audio- oder Video-Datei $input und schreibe ihn auf Datei $output.

Die Extraktion erfolgt ohne Transcoding, also ohne Qualitätsverlust.

=cut

# -----------------------------------------------------------------------------

sub extract {
    my $class = shift;
    # @_: $input,$output,@opt

    # Optionen und Argumente

    my $name = undef;
    my $play = 0;
    my $start = undef;
    my $stop = undef;
    
    Quiq::Option->extract(\@_,
        -name => \$name,
        -play => \$play,
        -start => \$start,
        -stop => \$stop,
    );
    if (@_ == 0 || @_ > 2) {
        $class->throw('Usage: $ffm->extract($input,$output,@opt)');
    }
    my $input = shift;
    my $output = shift;

    my $self = $class->new;
    $self->addInput($input);
    if (defined $start) {
        $start = Quiq::Duration->stringToSeconds($start);
    }
    if (defined $stop) {
        $stop = Quiq::Duration->stringToSeconds($stop);
    }
    $self->addStartStop($start,$stop);

    if ($play) {
        $self->prependString($play == 1? 'ffplay -autoexit': 'ffplay');
        $self->addOption(-vf=>'scale=720*a:720');
    }
    else {
        my $inp = $self->input(0);
        $self->outName($name);
        # Rausgenommen, da Fehler bei Extraktion aus Audio-Datei.
        # Bei Video nötig?
        # $self->outSize($inp->size);
        $self->outStart($start || 0);
        $self->outStop($stop || $inp->duration);
        $self->prependString('ffmpeg -y');

        $self->addOption(-codec=>'copy');
        $self->addOutput($output);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head3 extract169To43() - Extrahiere/Croppe 16:9-Video zu 4:3-Video

=head4 Synopsis

    $cmd = $class->extract169To43($input,$output,@opt);

=head4 Arguments

=over 4

=item $input

Eingabe-Datei.

=item $output

Ausgabe-Datei. Wenn undef, wird der Name der Ausgabedatei generiert.

=back

=head4 Options

=over 4

=item -bitrate => $x (Default: undef)

Die Bitrate des generierten Video in kb/s.

=item -name => $str (Default: undef)

Füge dem Dateinamen die Bezeichnung $str hinzu.

=item -play => 0|1|2 (Default: 0)

Zeige das generierte Video im Player an, statt es in einer Datei
zu speichern. Bei -play=>2 bleibt das Fenster des Players
offen, bis es per Hand geschlossen wird.

=item -start => $s (Default: 0)

Start-Position in Sekunden (mit Millisekunden als Nachkommastellen).

=item -stop => $s (Default: undef)

Ende-Position in Sekunden (mit Millisekunden als Nachkommastellen).

=item -xOffset => $n (Default: undef)

Crop-Offset in x-Richtung. Per Default croppt der crop-Filter mittig.

=back

=head4 Description

Croppe 16:9-Video $input zum 4:3-Video $output. Die Crop-Operation
schneidet links und rechts einen Teil des Video ab.

=cut

# -----------------------------------------------------------------------------

sub extract169To43 {
    my $class = shift;
    # @_: $input,$output,@opt

    # Optionen und Argumente

    my $bitrate = undef;
    my $name = undef;
    my $play = 0;
    my $start = undef;
    my $stop = undef;
    my $xOffset = undef;

    Quiq::Option->extract(\@_,
        -bitrate => \$bitrate,
        -name => \$name,
        -play => \$play,
        -start => \$start,
        -stop => \$stop,
        -xOffset => \$xOffset,
    );
    if (@_ == 0 || @_ > 2) {
        $class->throw('Usage: $ffm->extract169To43($input,$output,@opt)');
    }
    my $input = shift;
    my $output = shift;

    # Operation ausführen

    # * Command-Objekt instantiieren    
    my $self = $class->new;
    
    # * Input
    $self->addInput($input);
    
    # * Filter
    
    my @filter;

    # ** crop
    
    my ($width,$height) = $self->input(0)->size;
    my $newWidth = $height/3*4;
    if (!defined $xOffset) {
        $xOffset = ($width-$newWidth)/2;
    }
    push @filter,$self->cropFilter($newWidth,$height,$xOffset,0);

    # ** scale (im Falle von play)
    
    if ($play) {
        push @filter,$self->scaleFilter('720*a',720);
    }
    
    $self->addFilter('-vf',\@filter,',');

    # * Output-Optionen

    $self->addStartStop($start,$stop);
    $self->addBitrate($bitrate || $self->input(0)->bitrate);

    # * Output
    
    if ($play) {
        $self->prependString($play == 1? 'ffplay -autoexit': 'ffplay');
    }
    else {
        $self->outName($name);
        $self->outSize($newWidth,$height);
        $self->outStart($start || 0);
        $self->outStop($stop || $self->input(0)->duration);

        $self->prependString('ffmpeg -y');
        $self->addOutput($output);
    }
        
    return $self;
}

# -----------------------------------------------------------------------------

=head3 videoInfo() - Schreibe Video-Stream-Information in XML

=head4 Synopsis

    $cmd = $class->videoInfo($input);
    $cmd = $class->videoInfo($input,$streamIndex);

=head4 Arguments

=over 4

=item $input

Eingabe-Datei.

=item $streamIndex (Default: 0)

Index des Video-Stream.

=back

=head4 Description

Erzeuge eine ffprobe-Kommandozeile, die Information über den
Video-Stream $streamIndex in Datei $input liefert. Ist kein
Stream-Index angegeben, wird der erste Stream (Index 0) genommen.

=cut

# -----------------------------------------------------------------------------

sub videoInfo {
    my $class = shift;
    my $input = shift;
    my $streamIndex = shift || 0;

    my $self = $class->new;
    
    $self->addString('ffprobe');
    $self->addOption(-loglevel=>'error');
    $self->addOption(-print_format=>'xml');
    $self->addOption('-show_streams');
    $self->addOption(-select_streams=>"v:$streamIndex");
    $self->addInput($input);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Kommando-Ausführung

=head3 execute() - Führe FFmpeg-Kommandozeile aus

=head4 Synopsis

    $cmd->execute;

=head4 Description

Führe FFmpeg-Kommando $cmd aus. Als Ausgabe erscheint lediglich
die Fortschrittsanzeige.

=cut

# -----------------------------------------------------------------------------

sub execute {
    my $self = shift;

    my $cmd = $self->command;
    my $fh = Quiq::FileHandle->open('-|',"($cmd 2>&1)");
    local $/ = "\r";
    $| = 1;
    while (<$fh>) {
        if (/^(ffmpeg|ffplay|ffprobe|Input|Output)/) {
            next;
        }
        s/\n+$/\n/;
        print;
    }
    $fh->close;

    return;
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
