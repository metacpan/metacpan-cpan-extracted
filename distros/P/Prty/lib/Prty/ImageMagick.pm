package Prty::ImageMagick;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.123;

use Prty::Shell;
use Prty::File::Image;
use Prty::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::ImageMagick - Konstruiere eine ImageMagick-Kommandozeile

=head1 BASE CLASS

L<Prty::Hash>

=head1 DESCRIPTION

ImageMagick Online-Dokumentation:
L<http://www.imagemagick.org/Usage/>

Ein Objekt der Klasse repräsentiert eine
ImageMagick-Kommandozeile.  Die Klasse verfügt einerseits über
I<elementare> (Objekt-)Methoden, um eine solche Kommandozeile
sukzessive aus ihren elementaren Bestandteilen konstruieren zu
können und I<höhere> (Klassen-)Methoden, die eine bestimmte
Funktion durch das Hinzufügen einer Reihe von Optionen
realisieren.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $cmd = $class->new;

=head4 Description

Instantiiere ein ImageMagick-Kommandozeilen-Objekt und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    return $class->SUPER::new(
        cmd=>'',
    );
}
    

# -----------------------------------------------------------------------------

=head2 Kommando konstruieren

=head3 addElement() - Füge ein Kommandozeilen-Element hinzu

=head4 Synopsis

    $cmd->addElement($str);

=head4 Description

Ergänze die Kommandozeile um Kommandozeilen-Element $str.
Ein Kommandozeilen-Element ist ein durch Whiltespace getrennter
elementarer Teil der Kommandozeile, wie z.B. das Kommando, eine Option,
ein Optionsargument, ein Dateiname usw.

Enthält $str Whitespace oder andere, spezielle Zeichen, wird
$str in einfache Anführungsstriche eingefasst.

=head4 Examples

Ohne Whitespace:

    $cmd->addElement('input.jpg');
    =>
    input.gif

Mit Whitespace:

    $cmd->addElement('Sonne am Abend.jpg');
    =>
    'Sonne am Abend.jpg'

=cut

# -----------------------------------------------------------------------------

sub addElement {
    my ($self,$arg) = @_;

    my $ref = $self->getRef('cmd');
    if ($$ref) {
        $$ref .= ' ';
    }
    if ($arg =~ /[\s!#]/) {
        $$ref .= "'$arg'";
    }
    else {
        $$ref .= $arg;
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 addCommand() - Füge Kommando hinzu

=head4 Synopsis

    $cmd->addCommand($command);

=head4 Description

Ergänze die Kommandozeile am Anfang um das Kommando $command.
Die Methode liefert keinen Wert zurück.

=head4 Examples

Kommando convert:

    $cmd->addCommand('convert');
    =>
    convert

=cut

# -----------------------------------------------------------------------------

sub addCommand {
    my ($self,$command) = @_;
    
    my $ref = $self->getRef('cmd');
    $$ref = $$ref? "$command $$ref": $command;

    return;
}

# -----------------------------------------------------------------------------

=head3 addOption() - Füge Option hinzu

=head4 Synopsis

    $cmd->addOption($opt);
    $cmd->addOption($opt=>$val);

=head4 Description

Ergänze die Kommandozeile um die Option $opt und (optional) den
Wert $val. Die Methode liefert keinen Wert zurück.

=head4 Examples

Option ohne Wert:

    $cmd->addOption('-negate');
    =>
    -negate

Option mit Wert:

    $cmd->addOption(-rotate=>90);
    =>
    -rotate 90

=cut

# -----------------------------------------------------------------------------

sub addOption {
    my $self = shift;
    my $opt = shift;
    # @_: $val

    if (@_) {
        if (!defined($_[0]) || $_[0] eq '') {
            # Option UND Wert weglassen, wenn der Wert undef oder '' ist
            return;
        }
    }

    $self->addElement($opt);
    if (@_) {
        # Wert nur hinzufügen, wenn angegeben
        $self->addElement(shift);
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head2 Kommando

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

=head2 Kommando-Ausführung

=head3 execute() - Führe ImageMagick-Kommandozeile aus

=head4 Synopsis

    $cmd->execute;

=head4 Description

Führe ImageMagick-Kommando $cmd aus. Im Fehlerfall wird eine
Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub execute {
    my $self = shift;

    my $cmd = $self->command;
    print "$cmd\n";
    Prty::Shell->exec($cmd);

    return;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden (vollständige Kommandozeilen)

=head3 resizeFill() - Generiere Kommando für Operation resizeFill

=head4 Synopsis

    $cmd = $class->resizeFill($input,$output,$size,$background);

=head4 Arguments

=over 4

=item $input

Image-Objekt oder Bilddatei-Pfad des Input-Bildes.

=item $output

Bilddatei-Pfad des Output-Bildes. Das Verzeichnis wird erzeugt

=item $size

Größe des generierten Output-Bildes.

=item $background

Farbe des Hintergrunds, wenn das Bild den Bereich $size nicht
vollständig ausfüllt.

=back

=head4 Description

Generiere ein convert-Kommando, dass das Input-Bild auf Größe
$size bringt.

=over 2

=item *

Ist das Bild in mindestens einer Dimension größer als $size,
wird es verkleinert.

=item *

Andernfalls wird das Bild in seiner Größe nicht verändert.

=item *

Vom Bild nicht abgedeckte Bereiche werden in Hintergrundfarbe
$background dargestellt.

=back

=cut

# -----------------------------------------------------------------------------

sub resizeFill {
    my $class = shift;
    my $input = shift;
    my $output = shift;
    my $size = shift;
    my $background = shift;

    # Bild-Objekt der Input-Datei
    my $img = ref $input? $input: Prty::File::Image->new($input);

    # Kommando erzeugen

    my $self = $class->new;
    $self->addCommand('convert');
    $self->addElement($img->path);
    my ($width,$height) = split /x/,$size;
    if ($img->width > $width || $img->height > $height) {
        # Sonderbehandlung, wenn die Input-Bild verkleinert werden muss
        $self->addOption(-sample=>$size);
    }
    $self->addOption(-background=>$background);
    $self->addOption(-gravity=>'center');
    $self->addOption(-extent=>$size);
    Prty::Path->mkdir($output,-createParent=>1); # Erzeuge Verzeichnis
    $self->addElement($output);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 resizeStretch() - Generiere Kommando für Operation resizeStretch

=head4 Synopsis

    $cmd = $class->resizeStretch($input,$output,$size);

=head4 Arguments

=over 4

=item $input

Image-Objekt oder Bilddatei-Pfad des Input-Bildes.

=item $output

Bilddatei-Pfad des Output-Bildes. Das Verzeichnis wird erzeugt

=item $size

Größe des generierten Output-Bildes.

=back

=head4 Description

Generiere ein convert-Kommando, dass das Input-Bild auf Größe
$size bringt.

=over 2

=item *

Weicht das Seitenverhltmis ab, wird das Bild verzerrt.

=back

=cut

# -----------------------------------------------------------------------------

sub resizeStretch {
    my $class = shift;
    my $input = shift;
    my $output = shift;
    my $size = shift;

    # Bild-Objekt der Input-Datei
    my $img = ref $input? $input: Prty::File::Image->new($input);

    # Kommando erzeugen

    my $self = $class->new;
    $self->addCommand('convert');
    $self->addElement($img->path);
    $self->addOption(-resize=>"$size!");
    Prty::Path->mkdir($output,-createParent=>1); # Erzeuge Verzeichnis
    $self->addElement($output);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 negate() - Generiere Kommando für Operation negate

=head4 Synopsis

    $cmd = $class->negate($input,$output);

=head4 Arguments

=over 4

=item $input

Image-Objekt oder Bilddatei-Pfad des Input-Bildes.

=item $output

Bilddatei-Pfad des Output-Bildes. Das Verzeichnis wird erzeugt

=back

=head4 Description

Generiere ein convert-Kommando, dass das Input-Bild negiert.

=cut

# -----------------------------------------------------------------------------

sub negate {
    my $class = shift;
    my $input = shift;
    my $output = shift;

    # Bild-Objekt der Input-Datei
    my $img = ref $input? $input: Prty::File::Image->new($input);

    # Kommando erzeugen

    my $self = $class->new;
    $self->addCommand('convert');
    $self->addElement($img->path);
    $self->addOption(-channel=>'green');
    $self->addOption('-negate');
    Prty::Path->mkdir($output,-createParent=>1); # Erzeuge Verzeichnis
    $self->addElement($output);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 morph() - Generiere Kommando für Operation morph

=head4 Synopsis

    $cmd = $class->morph($input1,$input2,$outPattern,$morph);

=head4 Arguments

=over 4

=item $input1

Image-Objekt oder Bilddatei-Pfad des ersten Input-Bildes.

=item $input2

Image-Objekt oder Bilddatei-Pfad des zweiten Input-Bildes.

=item $outPattern

Pfad-Muster für die generierte Bildfolge.

=back

=head4 Description

Generiere ein convert-Kommando, das Zwischenbilder für die
Bilder $input1 und $input2 erzeugt und unter dem Pfad-Muster
speichert.

=cut

# -----------------------------------------------------------------------------

sub morph {
    my $class = shift;
    my $input1 = shift;
    my $input2 = shift;
    my $outPattern = shift;
    my $morph = shift;

    # Bild-Objekte der Input-Dateien

    my $img1 = ref $input1? $input1: Prty::File::Image->new($input1);
    my $img2 = ref $input2? $input2: Prty::File::Image->new($input2);

    # Kommando erzeugen

    my $self = $class->new;
    $self->addCommand('convert');
    $self->addElement($img1->path);
    $self->addElement($img2->path);
    $self->addOption(-morph=>$morph);
    $self->addOption(-delay=>0); # nötig?
    Prty::Path->mkdir($outPattern,-createParent=>1); # Erzeuge Verz.
    $self->addElement($outPattern);

    return $self;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.123

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
