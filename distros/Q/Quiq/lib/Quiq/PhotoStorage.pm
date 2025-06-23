# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PhotoStorage - Foto-Speicher

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Speicher für Fotos. Der Speicher
besitzt folgende Eigenschaften:

=over 2

=item *

Der Name der Foto-Datei bleibt als Bestandteil erhalten
(nach Anwendung von: s/[^-_a-zA-Z0-9]/_/g)

=item *

Jedes Foto erhält eine fortlaufende, eindeutige Zahl als Präfix

=item *

Es wird der SHA1-Hash der Datei gebildet und gespeichert

=item *

Jede Datei wird nur einmal gespeichert, d.h. Dubletten werden
zurückgewiesen

=item *

Andere Bildformate als JPEG werden nach JPEG konvertiert

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::PhotoStorage;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::LockedCounter;
use Quiq::Hash::Db;
use Quiq::Shell;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $pst = $class->new($dir);

=head4 Description

Öffne den Fotospeicher in Verzeichnis $dir.

Das Verzeichnis hat den Aufbau:

  $dir/pic/<NNNNNNN>-<NAME>.jpg  # Verzeichnis mit den Bildern
       cnt.txt                   # Stand der Nummer NNNNNNN
       sha1.hash                 # die SHA1-Hashes der Bilddateien

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dir) = @_;

    my $p = Quiq::Path->new;

    if (!$p->exists($dir)) {
        $class->throw(
            'PHOTOSTORAGE-00099: Directory does not exist',
            Dir => $dir,
        );
    }

    $p->mkdir("$dir/dup");
    $p->mkdir("$dir/pic");
    my $cnt = Quiq::LockedCounter->new("$dir/cnt.txt");
    my $h = Quiq::Hash::Db->new("$dir/sha1.hash",'rw');

    return $class->SUPER::new(
        dir => $dir,
        cnt => $cnt,
        h => $h,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 add() - Füge Fotodatei zum Speicher hinzu

=head4 Synopsis

  $path = $pst->add($file,@opt);

=head4 Arguments

=over 4

=item $file

Pfad der Fotodatei.

=back

=head4 Options

=over 4

=item -removeName = $bool (Default: 0)

Entferne den urprünglichen Dateinamen. Wenn nicht gesetzt, wird der
ursprüngliche Dateiname (in Kleinschreibung und ohne "Sonderzeichen")
mit "-" getrennt an den Zähler angefügt.

=back

=head4 Returns

(String) Pfad der Datei im Speicher.

=head4 Description

Füge Fotodatei $file zum Speicher hinzu und liefere den Pfad der Datei
im Speicher zurück.

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;
    # @_: $file,@opt

    my ($dir,$cnt,$h) = $self->get(qw/dir cnt h/);

    # Optionen und Argumente

    my $removeName = 0;

    my $argA = $self->parameters(1,1,\@_,
        -removeName => \$removeName,
    );
    my $file = Quiq::Path->expandTilde(shift @$argA);

    my $p = Quiq::Path->new;
    my $sha1 = $p->sha1($file);

    my $doublet = $h->get($sha1)? 1: 0;

    my $basename = $p->basename($file);
    my $ext = lc $p->extension($file);
    if ($ext eq 'jpg' || $ext eq 'jpeg') {
        # Bild ist JPEG
    }
    elsif ($ext eq 'png' || $ext eq 'webp' || $ext eq 'gif') {
        # Bilddatei nach JPEG wandeln
        
        my $sh = Quiq::Shell->new;
        $sh->exec(qq/convert "$file" "$file.jpg"/);
        $p->delete($file);
        $file = "$file.jpg";
    }
    else {
        $self->throw(
            'PHOTOSTORAGE-00099: Unknown file format',
            File => $file,
        );
    }

    my $n = $cnt->increment->count;
    my $destFile;
    if ($removeName) {
        $destFile = sprintf '%s/%s/%07d.jpg',$dir,$doublet? 'dup': 'pic',$n;
    }
    else {
        $basename =~ s/[^-_a-zA-Z0-9]/_/g;
        $destFile = sprintf '%s/%s/%07d-%s.jpg',$dir,$doublet? 'dup': 'pic',
            $n,$basename;
    }
    $p->duplicate('move',$file,$destFile);
    say $destFile;
    $h->{$sha1}++;

    return $destFile;
}

# -----------------------------------------------------------------------------

=head3 addAllByTime() - Füge Fotodateien zum Fotospeicher hinzu

=head4 Synopsis

  @paths = $pst->addAllByTime(@files,@opt);

=head4 Arguments

=over 4

=item $file

Pfad der Fotodatei.

=back

=head4 Options

=over 4

=item -removeName = $bool (Default: 0)

Entferne den urprünglichen Dateinamen. Wenn nicht gesetzt, wird der
ursprüngliche Dateiname (in Kleinschreibung und ohne "Sonderzeichen")
mit "-" getrennt an den Zähler angefügt.

=back

=head4 Returns

(Array of Strings) Liste der Pfade der Dateien im Speicher.

=head4 Description

Füge die Fotodateien @files in der Reihenfolge ihrer mtime
zum Speicher hinzu und liefere die Pfade der Dateien
im Speicher zurück.

=cut

# -----------------------------------------------------------------------------

sub addAllByTime {
    my $self = shift;
    # @_: @files,@opt

    my $p = Quiq::Path->new;
    
    # Optionen und Argumente

    my $removeName = 0;

    my $argA = $self->parameters(0,undef,\@_,
        -removeName => \$removeName,
    );
    my @files = map {$p->expandTilde($_)} @$argA;

    # Führe Operation aus

    @files = sort {$p->mtime($a) <=> $p->mtime($b)} @files;

    my @paths;
    for my $file (@files) {
        push @paths,$self->add($file,-removeName=>$removeName);
    }

    return @paths;
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
