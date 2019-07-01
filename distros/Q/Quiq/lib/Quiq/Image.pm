package Quiq::Image;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Option;
use Quiq::Path;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Image - Operationen im Zusammenhang mit Bildern/Bilddateien

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 aspectRatio() - Seitenverhältnis eines Bildes

=head4 Synopsis

    $aspectRatio = $this->aspectRatio($width,$height);

=head4 Description

Liefere das Seitenverhältnis eines Bildes, gegeben dessen
Breite und Höhe. Mögliche Rückgabewerte: '16:9', '4:3' oder (bei
anderen Seitenverhltnissen) der Quotient $width/$height.

=cut

# -----------------------------------------------------------------------------

sub aspectRatio {
    my ($this,$width,$height) = @_;

    if ($width/16*9 == $height) {
         return '16:9';
    }
    elsif ($width/4*3 == $height) {
         return '4:3';
    }

    return $width/$height;
}

# -----------------------------------------------------------------------------

=head3 findImages() - Suche Bild-Dateien

=head4 Synopsis

    @files|$fileA = $class->findImages(@filesAndDirs);
    @images|$imageA = $class->findImages(@filesAndDirs,-objects=>1);

=head4 Options

=over 4

=item -object => $class (Default: undef)

Liefere Objekte vom Typ $class statt Dateinamen.

=item -sort => 'mtime'|'name' (Default: undef)

Sortiere die Bilder primär nach Zeit (und sekundär nach Name)
oder nach Name. Per Default werden die Bilder unsortiert geliefert.

=back

=head4 Description

Liefere die Liste aller Bild-Dateien, die in @filesAndDirs
vorkommen. Vereichnisse werden rekursiv nach Bild-Dateien
durchsucht.

Als Bild-Dateien werden alle Dateien angesehen, die eine
Bild-Extension (.jpg, .png, .gif) besitzen. Bei Dateien ohne
Extension wird mittels Quiq::Image->type() geprüft, ob es sich
um eine Bild-Datei handelt.

=cut

# -----------------------------------------------------------------------------

sub findImages {
    my $class = shift;
    # @_: @filesAndDirs 
    
    # Optionen

    my $object = 0;
    my $sort = '';

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -object => \$object,
        -sort => \$sort,
    );

    my @arr;
    for my $path (@_) {
        if (-d $path) {
            my @tmp;
            for my $file (Quiq::Path->find($path,-type=>'f')) {
                my $ext = Quiq::Path->extension($file);
                if ($ext) {
                    if ($ext =~ /^(jpe?g|gif|png)$/i) {
                        # Bild an Endung erkannt
                        push @tmp,$file;
                    }
                }
                elsif ($class->type($file,-sloppy=>1)) {
                    # Bild an Magic-Bytes erkannt
                    push @tmp,$file;
                }
            }

            # Verzeichnis-Dateien sortieren
        
            if ($sort eq 'mtime') {
                @tmp = sort {(stat $a)[9]<=>(stat $b)[9] || $a cmp $b} @tmp;
            }
            elsif ($sort eq 'name') {
                @tmp = sort @tmp;
            }

            # Verzeichnis-Dateien an Gesamt-Liste anhängen
            push @arr,@tmp;    
        }
        else {
            push @arr,$path;
        }
    }

    if ($object) {
        for (my $i = 0; $i < @arr; $i++) {
            $arr[$i] = $object->new($arr[$i]);
        }
    }
    
    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 standardName() - Standard-Name eines Bildes

=head4 Synopsis

    $standardName = $class->standardName($n,$width,$height,$extension,@opt);

=head4 Options

=over 4

=item -name => $name

Ergänzender Text zum Bild.

=back

=head4 Description

Erzeuge einen Standard-Bild-Namen und liefere diesen zurück.
Ein Standard-Bild-Name hat den Aufbau:

    NNNNNN-WIDTHxHEIGHT[-NAME].EXT

Hierbei ist:

=over 4

=item NNNNNN

Die Bildnummer $i. Diese wird mit führenden Nullen auf sechs
Stellen gebracht.

=item WIDTH

Die Breite des Bildes.

=item HEIGHT

Die Höhe des Bildes.

=item NAME

Ein ergänzender Text zum Bild. Dieser ist optional. Leerzeichen
werden durch Bindestriche (-) ersetzt.

=item EXT

Die Datei-Endung, die sich aus dem Typ des Bildes ableitet,
z.B. 'jpg', 'png', 'gif' usw.

=back

=cut

# -----------------------------------------------------------------------------

sub standardName {
    my $class = shift;
    my $n = shift;
    my $width = shift;
    my $height = shift;
    my $extension = shift;
        
    # Optionen

    my $name = undef;

    Quiq::Option->extract(\@_,
        -name=>\$name,
    );
    
    if ($n < 1 || $n > 999999) {
        $class->throw;
    }

    my $str = sprintf '%06d-%dx%d',$n,$width,$height;
    if (defined($name) && $name ne '') {
        $name =~ s/\s+/-/g;
        $str .= "-$name";
    }
    $str .= ".$extension";
    
    return $str;
}

# -----------------------------------------------------------------------------

=head3 type() - Typ einer Bilddatei

=head4 Synopsis

    $type = $class->type($file,@opt);

=head4 Options

=over 4

=item -enum => $i (Default: 0)

Die Typbezeichnung, die geliefert wird:

=over 4

=item Wert: 0 oder nicht angegeben

'jpg', 'png', 'gif'

=item Wert: 1

'jpeg', 'png', 'gif'

=back

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn der Bild-Typ nicht erkannt wird, sondern
liefere einen Leerstring ('').

=back

=head4 Description

Ermittele den Typ der Bilddatei $file anhand seiner Magic-Bytes
und liefere diesen zurück. Drei Bildtypen werden erkannt:

=over 2

=item *

JPEG

=item *

PNG

=item *

GIF

=back

Wird der Bildtyp nicht erkannt, wirft die Methode eine Exception,
sofern nicht die Option -sloppy gesetzt ist.

Anstelle eines Dateinamens kann auch eine Skalarreferenz
(in-memory Bild) übergeben werden.

=cut

# -----------------------------------------------------------------------------

sub type {
    my $class = shift;
    my $file = shift;
    # @_: @opt

    # Optionen

    my $enum = 0;
    my $sloppy = 0;

    Quiq::Option->extract(\@_,
        -enum => \$enum,
        -sloppy => \$sloppy,
    );

    # Operation ausführen
    
    my $fh = Quiq::FileHandle->new('<',$file);
    my $data = $fh->read(8);
    $fh->close;

    if ($data =~ /^\xff\xd8\xff/) {
        return $enum? 'jpeg': 'jpg';
    }
    elsif ($data =~ /^\x89PNG\r\n\x1a\n/) {
        return 'png';
    }
    elsif ($data =~ /^(GIF89a|GIF87a)/) {
        return 'gif';
    }
    elsif (!$sloppy) {
        $class->throw(
            'IMG-00001: Unknown image type',
            File => $file,
            Data => $data,
        );
    }

    return '';
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
