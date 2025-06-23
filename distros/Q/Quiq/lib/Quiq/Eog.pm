# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Eog - Operationen mit eog

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Eog;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Trash;
use Quiq::Shell;
use Quiq::Path;
use Quiq::Terminal;
use Quiq::DirHandle;
use Quiq::Array;
use Quiq::Eog;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 pickImages() - Wähle Bilddateien mit eog aus

=head4 Synopsis

  @files|$fileA = $class->pickImages(@filesAndDirs);

=head4 Arguments

=over 4

=item @filesAndDirs

Liste von Bilddateien und Verzeichnissen mit Bilddateien. Eog ermittelt
die Bilddateien in Verzeichnissen eigenständig, aber nicht rekursiv.

=back

=head4 Returns

Liste von Bildpfaden, im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Zeige die Bilddateien mit C<eog> an. Bilder, die in C<eog> mit C<DEL>
gelöscht werden, landen im Trash. Nach Verlassen von C<eog> kehrt die
Methode zurück und liefert die Liste aller Dateien im Trash. Diese
können dann nach Belieben verarbeitet werden.

Ist der Trash bei Aufruf der Methode nicht leer, wird gefragt, ob
die Dateien im Trash vorab gelöscht werden sollen.

=cut

# -----------------------------------------------------------------------------

sub pickImages {
    my $class = shift;
    # @_: @filesAndDirs 

    my $t = Quiq::Trash->new;
    $t->emptyTrash(1); # Leere Trash nach Rückfrage

    Quiq::Shell->exec("eog @_ 2>/dev/null");

    # Ermittele die Dateien im Trash
    my $fileA = $t->files;

    return wantarray? @$fileA: $fileA;
}

# -----------------------------------------------------------------------------

=head3 show() - Zeige Bilddateien an

=head4 Synopsis

  $class->show($op, $dir,$tmpDir);

=head4 Arguments

=over 4

=item $op

Art der Reihenfolge: C<mtime>, C<random>, C<reverse>

=item $dir

Verzeichnis, in dem sich die Bilddateien befinden

=item $tmpDir

Verzeichnis, in dem die Bilddateien in mtime-Reihenfolge verlinkt sind

=back

=head4 Description

Zeige mit C<eog> die Bilddateien in mtime-Reihenfolge aus
dem Verzeichnis $tmpDir an.

Ist $tmpDir bei Aufruf der Methode nicht leer, wird gefragt, ob
die Dateien darin vorab gelöscht werden sollen.

=cut

# -----------------------------------------------------------------------------

sub show {
    my ($class,$op,$dir,$tmpDir) = @_;

    my $p = Quiq::Path->new;

    if (!-d $dir) {
        $class->throw(
            'PARAM-00099: Directory does not exist',
            Dir => $dir,
        );
    }
    if (!-d $tmpDir) {
        $class->throw(
            'PARAM-00099: Directory does not exist',
            Dir => $tmpDir,
        );
    }
    if (!$p->isEmpty($tmpDir)) {
        my $answ = Quiq::Terminal->askUser("Delete all files in $tmpDir?",
            -values => 'y/n',
            -default => 'y',
        );
        if ($answ ne 'y') {
            return;
        }
        $p->deleteContent($tmpDir);
    }

    my @files;
    my $dh = Quiq::DirHandle->new($dir);
    while (my $e = $dh->next) {
        if ($e =~ /\.jpg$/) {
            push @files,"$dir/$e";
        }
    }
    $dh->close;

    my $i = 0;
    if ($op eq 'mtime') {
        @files = sort {$p->mtime($a) <=> $p->mtime($b)} @files;
    }
    elsif ($op eq 'random') {
        Quiq::Array->shuffle(\@files);
    }
    elsif ($op eq 'reverse') {
        @files = reverse sort @files
    }
    else {
        $class->throw(
            'PARAM-00099: Unknown operation',
            Op => $op,
        );
    }

    for my $srcFile (@files) {
        my $filename = $p->filename($srcFile);
        my $destFile = sprintf '%s/%06d-%s',$tmpDir,++$i,$filename;
        # say "$destFile -> $srcFile";
        $p->duplicate('symlink',$srcFile,$destFile);
    }

    Quiq::Shell->exec("eog $tmpDir");

    return;
}

# -----------------------------------------------------------------------------

=head3 transferImages() - Übertrage ausgewählte Bilder in ein anderes Verzeichnis

=head4 Synopsis

  $class->transferImages($srcDir,$destDir,@options);

=head4 Arguments

=over 4

=item $srcDir

Quellverzeichnis mit Bilddateien.

=item $destDir

Zielverzeichnis.

=back

=head4 Options

=over 4

=item -addExtension => $ext

Füge am Ende der Verarbeitung die Endung $ext zum Namen des
Quellverzeichnisses $srcDir I<nach Rückfrage> hinzu.

=item -nameToNumber => [$width,$step]

Wandele den Basisnamen der Bilddatei im Zielverzeichnis in eine Nummer.
Die Nummer hat die Breite $width mit führenden Nullen und wird
mit der Schrittweite $step weitergezählt. Enthält das Zielverzeichnis
bereits Dateien, wird ab der höchsten Nummer weiter gezählt.

=back

=head4 Description

Zeige die Bilddateien des Quellverzeichnisses $srcDir mit C<eog>
an. Bilder, die in C<eog> mit C<DEL> gelöscht werden, landen im
Trash. Nach Verlassen von C<eog> werden die Bilddateien aus dem Trash
ins Zielverzeichnis bewegt. Existiert das Zielverzeichnis nicht,
wird es erzeugt.

Die Methode ist so konzipiert, dass auch Dateien mit dem gleichen
Grundnamen wie die Bilddatei mitkopiert werden (z.B. .xfc-Dateien).
Daher arbeitet diese Methode anders als pickImages() mit genau
einem Quellverzeichnis, nicht mit mehreren Verzeichnissen/Dateinamen.

Ist der Trash bei Aufruf der Methode nicht leer, wird gefragt, ob
die Dateien im Trash vorab gelöscht werden sollen.

=head4 Example

  perl -MQuiq::Eog -E 'Quiq::Eog->transferImages("2024-10-16","ok",-addExtension=>"bak")'

=cut

# -----------------------------------------------------------------------------

sub transferImages {
    my ($class,$srcDir,$destDir) = splice @_,0,3;

    my $p = Quiq::Path->new;

    if (!-e $srcDir) {
        $class->throw(
            'EOG-00099: Source directory does not exist',
            Dir => $srcDir,
        );
    }

    if (!-e $destDir) {
        $class->throw(
            'EOG-00099: Destination directory does not exist',
            Dir => $destDir,
        );
    }

    # Optionen

    my $addExtension = undef;
    my $nameToNumber = undef;

    $class->parameters(0,0,\@_,
        -addExtension => \$addExtension,
        -nameToNumber => \$nameToNumber,
    );

    my ($number,$width,$step);
    if ($nameToNumber) {
        ($width,$step) = @$nameToNumber;
        $number = $p->maxFileNumber($destDir);
    }

    # Operation ausführen

    my $count = 0;
    my $dh = Quiq::DirHandle->new($srcDir);
    while (my $entry = $dh->next) {
        if ($entry =~ /\.jpg$/) { # FIXME: Weitere Bildformate
            $count++;
        }
    }
    $dh->close;
    say "$count Dateien";

    my $fileA = Quiq::Eog->pickImages($srcDir);
    for my $trashFile (@$fileA) {
        my @srcFiles = ($trashFile);
        my $srcBasePath = sprintf '%s/%s',$srcDir,$p->basename($trashFile);
        push @srcFiles,$p->glob("$srcBasePath.*"); # ggf. .xcf-Datei hinzu
        if (-d $srcBasePath) {
            push @srcFiles,$srcBasePath, # füge Verzeichnis hinzu
        }

        if ($nameToNumber) {
            $number += $step;
        }

        for my $srcFile (@srcFiles) {
            my $destFile;
            if ($nameToNumber) {
                my $ext = $p->extension($srcFile);
                if ($ext) {
                    $destFile = sprintf '%s/%0*d.%s',$destDir,$width,$number,$ext;
                }
                else {
                    $destFile = sprintf '%s/%0*d',$destDir,$width,$number; # Verzeichnis
                }
            }
            else {
                $destFile = sprintf '%s/%s',$destDir,$p->filename($srcFile);
            }

            say "$srcFile => $destFile";
            $p->rename($srcFile,$destFile);
            $p->touch($destFile);
        }
    }

    if (my $ext = $addExtension) {
        my $answ = Quiq::Terminal->askUser(
            "Add Extension $ext?",
            -values => 'y/n',
            -default => 'y',
        );
        if ($answ eq 'y') {
            $p->rename($srcDir,"$srcDir$ext");
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
