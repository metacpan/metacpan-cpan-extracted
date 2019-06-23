package Quiq::TimeLapse::Directory;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Path;
use Quiq::TimeLapse::File;
use Quiq::TimeLapse::RangeDef;
use Quiq::Option;
use Quiq::Image;
use Quiq::Progress;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TimeLapse::Directory - Bildsequenz-Verzeichnis

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

    # Klasse laden
    use Quiq::TimeLapse::Directory;
    
    # Instantiiere Verzeichnis-Objekt
    $tdr = Quiq::TimeLapse::Directory->new('/my/image/dir');
    
    # Anzahl der enthaltenen Bilder
    $n = $tdr->count;
    
    # Niedrigste Bildnummer
    $n = $tdr->minNumber;
    
    # Höchste Bildnummer
    $n = $tdr->maxNumber;
    
    # alle Bilder (des Verzeichnisses oder aus range.def, wenn definiert)
    @images = $tdr->images;
    
    # Bilder eines Nummernbereichs
    
    @images = $tdr->images('113-234');
    @images = $tdr->images('290-');
    @images = $tdr->images('422');
    
    # Bilder zu einem Bezeichner aus range.def
    @images = $tdr->images('autofahrt');
    
    # Alle Bilder des Verzeichnisses
    @images = $tdr->images('all');
    
    # Alle Bilder aus range.def (leer, wenn range.def nicht existiert)
    @images = $tdr->images('used');
    
    # Alle Bilder des Verzeichnisses, die nicht range.def vorkommen
    # (leer, wenn range.def nicht existiert)
    @images = $tdr->images('unused');
    
    # Lookup eines Bildes
    $img = $tdr->image(422); # liefert undef, wenn nicht existent
    
    # Liefere das Objekt mit den Range- und Clip-Definitionen. Über
    # dieses Objekt können die Bildfolgen von Ranges und Clips gezielt
    # abgerufen werden. Details siehe Quiq::TimeLapse::RangeDef
    $trd = $tdr->rangeDef;

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Verzeichnis, das eine
geordnete Liste von Bildern enthält, ggf. verteilt über mehrere
Unterverzeichnisse. Die Bilder können einzeln über ihre Bildnummer
oder als Bildfolge über die Angabe eines Nummern-Bereichs oder
eines Range- oder Clip-Bezeichners (definiert in der Datei
range.def) abgefragt werden.

Mit der Liste von Bildern kann eine Bildfolge
(Quiq::TimeLapse::Sequence) instantiiert werden, aus welcher
u.a. ein Video generiert werden kann. Siehe die Doku dieser Klasse.

=head1 ATTRIBUTES

=over 4

=item dir

Pfad des Verzeichnisses.

=item imageA

Array der Bilddatei-Objekte des Verzeichnisses, nach Bildnummer
sortiert.

=item imageH

Hash der Bilddatei-Objekte, mit Bildnummer als Schlüssel.

=item rangeDef

Referenz auf das Rangedatei-Objekt. Die Referenz wird beim ersten
Zugriff zugewiesen. Existiert die Datei range.def nicht, wird eine
Exception geworfen.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Bildverzeichnis-Objekt

=head4 Synopsis

    $tdr = $class->new($dir);

=head4 Arguments

=over 4

=item $dir

Wurzelverzeichnis.

=back

=head4 Returns

Referenz auf Bildverzeichnis-Objekt

=head4 Description

Instantiiere ein Bildverzeichnis-Objekt aus den Bildern in der
Verzeichnisstruktur $dir und liefere eine Referenz auf dieses
Objekt zurück. Die Verzeichnisstuktur wird per find() nach
Bilddateien durchsucht und kann daher beliebig tief verschachtelt
sein.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dir) = @_;

    # Bilddateien ermitteln

    my @images;
    for my $file (Quiq::Path->find($dir,-type=>'f')) {
        if ($file =~ /range.def$/) {
            next;
        }
        push @images,Quiq::TimeLapse::File->new($file);
    }

    # Bild-Array sortieren
    @images = sort {$a->number <=> $b->number} @images;

    # Bild-Hash aufbauen. Die Bildnummer muss eindeutig sein.

    my %hash;
    for my $img (@images) {
        my $n = $img->number;
        if ($hash{$n}) {
            $class->throw(
                'TIMELAPSE-00002: Duplicate image number',
                Number => $n,
                File => $img->path,
            );
        }
        $hash{$n} = $img;
    }

    # Sequenz-Objekt instantiieren

    return $class->SUPER::new(
        dir => $dir,
        imageA => \@images,
        imageH => \%hash,
        rangeDef => Quiq::TimeLapse::RangeDef->new($dir),
    );
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 dir() - Pfad des Zeitraffer-Verzeichnisses

=head4 Synopsis

    $path = $tdr->dir;
    $path = $tdr->dir($subPath);

=head4 Description

Liefere den Pfad des Zeitraffer-Verzeichnisses. Ist Zeichenkette
$subPath angegeben, wird diese mit '/' getrennt an den Pfad
angefügt.

=cut

# -----------------------------------------------------------------------------

sub dir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'dir'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 count() - Anzahl aller Bilder

=head4 Synopsis

    $n = $tdr->count;

=head4 Returns

Integer >= 0

=head4 Description

Liefere die Anzahl der im Zeitraffer-Verzeichnis enthaltenen Bilder.

=cut

# -----------------------------------------------------------------------------

sub count {
    my $self = shift;
    return scalar @{$self->imageA};
}

# -----------------------------------------------------------------------------

=head3 minNumber() - Niedrigste Bildnummer

=head4 Synopsis

    $n = $tdr->minNumber;

=head4 Returns

Integer >= 0

=head4 Description

Liefere die niedrigste Bildnummer. Die niedrigste Bildnummer ist
die Nummer des ersten Bildes. Ist die Liste leer, liefere 0.

=cut

# -----------------------------------------------------------------------------

sub minNumber {
    my $self = shift;
    return $self->count? $self->imageA->[0]->number: 0;
}

# -----------------------------------------------------------------------------

=head3 maxNumber() - Höchste Bildnummer

=head4 Synopsis

    $n = $tdr->maxNumber;

=head4 Returns

Integer >= 0

=head4 Description

Liefere die höchste Bildnummer. Die höchste Bildnummer ist die
Nummer des letzten Bildes. Ist die Liste leer, liefere 0.

=cut

# -----------------------------------------------------------------------------

sub maxNumber {
    my $self = shift;
    return $self->count? $self->imageA->[-1]->number: 0;
}

# -----------------------------------------------------------------------------

=head2 Bildnummern

=head3 numbers() - Bildnummern-Ausdruck zu Bildnummern-Liste

=head4 Synopsis

    @numbers|$numberA = $tdr->numbers($expr);

=head4 Returns

Liste von Bildnummern (Integer). Im Skalarkontext eine Referenz
auf die Liste.

=head4 Description

Liefere die Liste der Bildnummern zu Bildnummern-Ausdruck $expr.

=cut

# -----------------------------------------------------------------------------

sub numbers {
    my ($self,$expr) = @_;

    my $debug = 0;

    # 1. Bezeichner auflösen (anschließend enthält $expr
    #    keine Bezeichner mehr)

    while (1) {
        if ($debug) {
            printf "%d - %21s: %s\n",1,'Expression',$expr;
        }
        my $r = $expr =~ s/([-\w]*[a-zA-Z][-\w]*)(?![-\w]*\()/
            $self->resolveIdentifier($1)/eg;
        if (!$r) {
            last;
        }
    }
    
    # 2. Bereichsangaben auflösen (anschließend enthält $expr
    #    keine Bereichsangaben mehr)

    while (1) {
        if ($debug) {
            printf "%d - %21s: %s\n",2,'Identifiers resolved',$expr;
        }
        my $r = $expr =~ s/(^|[\s\(,])(\d+)-(\d+)($|[\s)])/
            $1.$self->resolveRange($2,$3).$4/eg;
        if (!$r) {
            last;
        }
    }
    
    # 3. Funktionen auflösen (anschließend besteht $expr
    #    nur noch aus Bildnummern)

    while (1) {
        if ($debug) {
            printf "%d - %21s: %s\n",3,'Ranges resolved',$expr;
        }
        my $r = $expr =~ s/([a-zA-Z]+)\(([^()]*)\)/
            $self->resolveFunctionExpression($1,$2)/eg;
        if (!$r) {
            last;
        }
    }
    if ($debug) {
        printf "%d - %21s: %s\n",4,'Functions applied',$expr;
    }
    
    # 4. Bildnummern-Liste erzeugen
    
    $expr =~ s/^\s+//;
    $expr =~ s/\s+$//;
    my @numbers = split /\s+/,$expr;
    
    if ($debug) {
        printf "%d - %21s: %s\n",5,'Existent numbers only',join(' ',@numbers);
    }
    return wantarray? @numbers: \@numbers;
}

# -----------------------------------------------------------------------------

=head3 resolveFunctionExpression() - Wende Funktion an

=head4 Synopsis

    $str = $tdr->resolveFunctionExpression($name,$args);

=head4 Returns

Zeichenkette

=head4 Description

Wende Funktion $func auf seine Argumente $args an und liefere die
resultierende Zeichenkette (Bildnummern-Aufzählung) zurück.

=cut

# -----------------------------------------------------------------------------

sub resolveFunctionExpression {
    my ($self,$func,$args) = @_;

    my @args = split /,/,$args;
    my @numbers = split /\s+/,pop @args;

    if ($func eq 'duplicate') {
        my $n = shift @args || 2;
        for (my $i = 0; $i < @numbers; $i += $n) {
            for (my $j = 1; $j < $n; $j++) {
                splice @numbers,$i+$j,0,$numbers[$i];
            }
        }
    }
    elsif ($func eq 'randomize') {
        my $n = shift @args || scalar @numbers;

        my @arr;
        my $size = scalar @numbers;
        for (my $i = 0; $i < $n; $i++) {
            my $m = int rand scalar $size;
            if ($size > 1 && @arr && $numbers[$m] == $arr[-1]) {
                redo;
            }
            push @arr,$numbers[$m];
        }
        @numbers = @arr;
    }
    elsif ($func eq 'repeat') {
        my $n = shift @args || 2;
        for (my $i = 1; $i < $n; $i++) {
            push @numbers,@numbers;
        }
    }
    elsif ($func eq 'reverse') {
        @numbers = reverse @numbers;
    }
    else {
        $self->throw(
            'TIMELAPSE-00001: Unknown function',
            Function => $func,
        );
    }

    return join ' ',@numbers;
}

# -----------------------------------------------------------------------------

=head3 resolveIdentifier() - Wert eines Clip- oder Range-Bezeichners

=head4 Synopsis

    $str = $tdr->resolveIdentifier($key);

=head4 Returns

Zeichenkette

=head4 Description

Liefere den Wert des Bezeichners $key.

=cut

# -----------------------------------------------------------------------------

sub resolveIdentifier {
    my ($self,$key) = @_;

    # Range-Definitionen
    my $trd = $self->rangeDef;
    
    my @arr;
    if ($key eq 'all') {
        # Die Nummern aller Bilder des Zeitraffer-Verzeichnisses
    
        for my $img (@{$self->{'imageA'}}) {
            push @arr,$img->number;
        }
    }
    elsif ($key eq 'used') {
        # Alle Range-Bezeichner. Wenn keine Range-Datei existiert,
        # leere Liste.

        for my $key ($trd->rangeKeys) {
            push @arr,$key;
        }
    }
    elsif ($key eq 'unused') {
        # Alle Bilder des Zeitraffer-Verzeichnisses, die in keinem
        # Range auftauchen. Wenn keine Range-Datei existiert, leere
        # Liste.

        if ($trd->rangeCount) {
            # Hash mit allen genutzten Bildern
    
            my %used;
            for my $n ($self->numbers('used')) {
                $used{$n}++;
            }

            # Liste der nicht-genutzten Bilder aufbauen

            for my $img (@{$self->{'imageA'}}) {
                my $n = $img->number;
                if (!$used{$n}) {
                    push @arr,$n
                }
            }
        }
    }
    elsif ($key eq 'junk') {
        if (my $expr = $trd->{'junkExpr'}) {
            # Hash mit allen genutzten Bildern
    
            my %used;
            for my $n ($self->numbers('used')) {
                $used{$n}++;
            }

            # Liste der Junk-Bilder, die nicht in %used vorkommen

            for my $n ($self->numbers($expr)) {
                if (!$used{$n}) {
                    push @arr,$n
                }
            }

            # Bildnummern aufsteigend sortieren        
            @arr = sort {$a <=> $b} @arr;
        }
    }
    elsif (defined(my $expr = $trd->expression($key))) {
        if ($expr) {
            push @arr,$expr;
        }
    }
    else {
        $self->throw(
            'TIMELAPSE-00001: Unknown identifier',
            Key => $key,
            Directory => $self->dir,
        );
    }

    return join ' ',@arr;
}

# -----------------------------------------------------------------------------

=head3 resolveRange() - Löse Bildnummern-Bereichsangabe auf

=head4 Synopsis

    $str = $tdr->resolveRange($n,$m);

=head4 Returns

Aufzählung von Bildnummern als Zeichenkette

=head4 Description

Überführe eine Bildnummern-Bereichsangabe ("N-M") in eine
Nummern-Aufzählung ("N ... M").

=cut

# -----------------------------------------------------------------------------

sub resolveRange {
    my ($self,$n,$m) = @_;

    my $str = '';
    for (my $i = $n; $i <= $m; $i++) {
        if ($str) {
            $str .= ' ';
        }
        $str .= $i;
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head2 Bilddateien

=head3 images() - Folge von Bilddatei-Objekten

=head4 Synopsis

    @images|$imageA = $tdr->images;
    @images|$imageA = $tdr->images($expr);

=head4 Arguments

=over 4

=item $expr

Bildfolgen-Ausdruck.

=back

=head4 Returns

Liste von Bilddatei-Objekten. Im Skalarkontext liefere eine
Referenz auf die Liste.

=head4 Description

Liefere eine Folge von Bilddatei-Objekten gemäß
Bildfolgen-Ausdruck $expr. Ist kein Bildfolgen-Ausdruck angegeben,
liefere alle Bilddatei-Objekte. Ist eine Range-Datei definiert,
bedeutet "alle", alle I<genutzten> Bilder (= 'used'), ansonsten
ausnahmslos alle Bilder des Zeitraffer-Verzeichnisses (= 'all').

Die Methode cached ihre Ergebnisse, so dass jede Bildfolge nur
einmal bestimmt wird.

=cut

# -----------------------------------------------------------------------------

my %ImageSequence;
    
sub images {
    my $self = shift;
    my $expr = shift || ($self->rangeDef->rangeCount? 'used': 'all');

    my $imageA = $ImageSequence{$expr};
    if (!$imageA) {
        my @images;
        for my $n ($self->numbers($expr)) {
            if (my $img = $self->image($n)) {
                push @images,$img;
            }
        }
        $imageA = $ImageSequence{$expr} = \@images;
    }
    
    return wantarray? @$imageA: $imageA;
}

# -----------------------------------------------------------------------------

=head3 image() - Lookup Bilddatei-Objekt nach Bild-Nummer

=head4 Synopsis

    $img = $tdr->image($n);

=head4 Arguments

=over 4

=item $n

Bild-Nummer

=back

=head4 Returns

Bild-Objekt oder C<undef>.

=head4 Description

Liefere das Bild-Objekt mit Bild-Nummer $n. Existiert keine
Bild-Objekt mit Nummer $n, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub image {
    my ($self,$n) = @_;

    # Wir prüfen auf korrekten Integer-Wert
    
    if ($n !~ /^\d+$/) {
        $self->throw(
            'TIMELAPSE-00001: Not an integer',
            Key => !defined $n? 'undef': $n eq ''? "''": $n,
        );
    }

    return $self->{'imageH'}->{$n};
}

# -----------------------------------------------------------------------------

=head2 Operationen

=head3 importImages() - Importiere Bilddateien in Zeitraffer-Verzeichnis

=head4 Synopsis

    $class->importImages($dir,$srcDir);

=head4 Arguments

=over 4

=item $dir

Zeitraffer-Verzeichnis, in das importiert wird.

=item $srcDir

Quell-Verzeichnisstruktur mit den Bildern, die importiert werden.

=back

=head4 Options

=over 4

=item -reorganize => $bool (Default: 0)

Rufe Methode reorganize()

=item -sort => 'name'|'mtime' (Default: 'name')

Sortierung der Bilddateien vor dem Import. Entweder nach Name
('name') oder nach letzter Änderung und sekundär Name
('mtime'). Letzeres ist beim Import von GoPro-Bildern wichtig.

=item -subDir => $subPath (Default: undef)

Importiere die Bilder in das Zeitraffer-Subverzeichnis $subPath.
Existiert das Verzeichnis nicht, wird es angelegt.

=item -verbose => $bool (Default: 1)

Gibt Laufzeitinformation auf STDOUT aus.

=back

=head4 Returns

nichts

=head4 Description

Füge die Bilddateien aus Verzeichnisstruktur $srcDir zum
Zeitraffer-Verzeichnis $dir hinzu.

=cut

# -----------------------------------------------------------------------------

sub importImages {
    my ($class,$dir,$srcDir) = splice @_,0,3;

    # Optionen
    
    my $reorganize = 0;
    my $sort = 'name';
    my $subDir = undef;
    my $verbose = 1;
    
    Quiq::Option->extract(\@_,
        -reorganize => \$reorganize,
        -sort => \$sort,
        -subdir => \$subDir,
        -verbose => \$verbose,
    );

    # Operation ausführen

    my $tdr = $class->new($dir);
        
    my @images = Quiq::Image->findImages(
        -sort => $sort,
        -object => 'Quiq::File::Image',
        $srcDir,
    );

    # Zielverzeichnis ist per Default das Zeitraffer-Verzeichnis
    my $destDir = $dir;
    
    if ($subDir) {
        # Subverzeichnis muss als relativer Pfad angegeben sein

        if ($subDir =~ m|^/|) {
            $class->throw(
                'TIMEPAPSE-00001: Path of subdir must be relative',
                Subdir => $subDir,
            );
        }

        # Pfad Zeitraffer-Verzeichnis voranstellen
        $destDir .= "/$subDir";
        
        # Subverzeichnis anlegen, falls es nicht existiert

        if (!-d $destDir) {
            Quiq::Path->mkdir($destDir,-recursive=>1);
        }
    }

    my $max = $tdr->maxNumber;
    my $mode = 'copy';
    
    my $pro = Quiq::Progress->new(scalar(@images),
        -show => $verbose,
    );
    my $i = 0;
    for my $img (@images) {
        $i++;
        my $destFile = sprintf '%s/%s',$destDir,
            Quiq::Image->standardName($max+$i,$img->width,
            $img->height,$img->type,-name=>$img->basename);
        print $pro->msg($i,'%s: i/n x% t/t(t) x/s: %s',$mode,$destFile);
        Quiq::Path->duplicate($mode,$img->path,$destFile,
            -preserve => 1,
        );
    }
    print $pro->msg;

    if ($reorganize) {
        $class->reorganize($dir);
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 reorganize() - Reorganisiere Bilddateien

=head4 Synopsis

    $class->reorganize($dir,@opt);

=head4 Arguments

=over 4

=item $dir

Pfad zum Zeitraffer-Verzeichnis.

=back

=head4 Options

=over 4

=item -dryRun => $bool (Default: 0)

Zeige Änderungen, führe sie aber nicht aus.

=back

=head4 Returns

nichts

=head4 Description

Reorganisiere die Bilddateien des Zeitraffer-Verzeichnisses,
indem sie nach ihrer Bildnummer auf Unterverzeichnisse mit
je 500 Bilddateien verteilt werden.

Es wird die Unterverzeichnisstruktur angelegt

    000001  (für Bilder mit Bildnummer 1 bis Bildnummer 500)
    000501  (Bildnummer 501 bis 1000)
    001001  (Bildnummer 1001 bis 1500)
    usw.

und die Bilder in ihr Verzeichnis bewegt. Befindet sich eine Bilddatei
bereits im richtigen Verzeichnis, wird sie nicht bewegt.

Anschließend werden leere Verzeichnisse gelöscht.

Die Operation kann wiederholt angewendet werden, an einem bereits
reorganisierten Verzeichnis wird keine Änderung vorgenommen.

=cut

# -----------------------------------------------------------------------------

sub reorganize {
    my ($class,$dir) = splice @_,0,2;
    # @_: @opt

    my $dryRun = 0;
    
    Quiq::Option->extract(\@_,
        -dryRun => \$dryRun,
    );

    my $subDirSize = 500;
    my $mode = 'move';

    # Instantiiere Verzeichnis-Objekt
    my $tdr = $class->new($dir);
    
    # Hash mit genutzten Bildern
    
    my %used;
    for my $img ($tdr->images('used')) {
        $used{$img->number}++;
    }
    
    # Verteile die Bilddateien auf Subverzeichnisse
    
    for my $img ($tdr->images('all')) {
        my $n = $img->number;
        
        my $subDir = sprintf '%s/%s/%06d',$dir,$used{$n}? 'used': 'unused',
            int(($n-1)/$subDirSize)*$subDirSize+1;
        if (!-e $subDir) {
            if (!$dryRun) {
                Quiq::Path->mkdir($subDir,-recursive=>1);
            }
            print "$subDir - directory created\n";
        }

        my $srcFile = $img->path;
        my $destFile = sprintf '%s/%s',$subDir,$img->filename;
        if ($destFile ne $srcFile) {
            print "$srcFile => $destFile\n";
            if (!$dryRun) {
                Quiq::Path->duplicate($mode,$srcFile,$destFile);
            }
        }
    }

    # Überzählige Verzeichnisse löschen

    for my $dir (sort Quiq::Path->find($dir,-type=>'d')) {
        if (Quiq::Path->isEmpty($dir)) {
            if (!$dryRun) {
                Quiq::Path->rmdir($dir);
            }
            print "$dir - directory deleted\n";
        }
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
