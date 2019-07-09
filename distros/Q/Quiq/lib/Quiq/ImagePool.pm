package Quiq::ImagePool;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Quiq::Path;
use Quiq::ImagePool::Directory;
use Quiq::Option;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ImagePool - Speicher für Bild-Dateien

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Pool-Objekt

=head4 Synopsis

    $ipl = $class->new($path);

=head4 Arguments

=over 4

=item $path

Pfad zum Pool-Verzeichnises.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$path) = @_;

    # Objekt instantiieren

    return $class->SUPER::new(
        root => $path,
        directoryH => {},
    );
}

# -----------------------------------------------------------------------------

=head2 Eigenschaften

=head3 root() - Wurzelverzeichnis des Image-Pool

=head4 Synopsis

    $path = $ipl->root;
    $path = $ipl->root($subPath);

=head4 Description

Liefere den Pfad des Wurzelverzeichnissess des Image-Pool. Ist
Argument $subPath angegeben, füge diesen Pfad zum Wurzelverzeichnis
hinzu.

=head4 Example

Mit Subpfad:

    $ipl->root('cache');
    =>
    <POOLDIR>/cache

=cut

# -----------------------------------------------------------------------------

sub root {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'root'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head2 Verzeichnisse

=head3 directory() - Lookup Directory-Objekt nach Name

=head4 Synopsis

    $dir = $ipl->directory($name);

=head4 Arguments

=over 4

=item $name

Name des Bild-Verzeichnisses

=back

=head4 Description

Liefere das Bild-Verzeichnis-Objekt mit Name $name. Das Objekt
wird gecached. Existiert das Verzeichnis nicht, wird eine
Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub directory {
    my ($self,$name) = @_;

    # Directory-Namen auf den Anfang 'YYYY-MM-DD-X' reduzieren

    ($name) = $name =~ /^(\d{4}-\d{2}-\d{2}-[A-Z])/;
    if (!$name) {
        $self->throw;
    }

    return $self->{'directoryH'}->{$name} //= do {
        my $pattern = sprintf '%s/dir/%s*',$self->root,$name;
        my $path = Quiq::Path->glob($pattern);
        Quiq::ImagePool::Directory->new($path);
    };
}

# -----------------------------------------------------------------------------

=head2 Cache

=head3 cacheFile() - Generiere Pfad einer Cache-Datei

=head4 Synopsis

    $path = $ipl->cacheFile($img,$op,@args);

=head4 Arguments

=over 4

=item $op

Bezeichner für die angewendete Bild-Operation.

=item @args

Argumente für die Bild-Operation.

=back

=head4 Description

Generiere einen Cache-Pfad für Bild $img und Bild-Operation $op
mit den Argumenten @args und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub cacheFile {
    my $self = shift;
    my $img = shift;
    # @_: @args

    my $cacheId;
    my $basename = $img->basename;
    my @path = split m|/|,$self->path;
    if ($path[-2] eq 'img') {
        $cacheId = "$path[-3]/$basename"; # Subdirectoy-Path
    }
    else {
        $cacheId = "$path[-2]/$basename"; # Cache-Path
    }
    
    my $file = $self->root('cache/img');
    $file .= sprintf '/%s,%s.%s',$cacheId,join('-',@_),$img->type;

    return $file;
}

# -----------------------------------------------------------------------------

=head2 Bilder

=head3 images() - Bilder gemäß Suchkriterium

=head4 Synopsis

    @images|$imageA = $ipl->images($key,@opt);

=head4 Arguments

=over 4

=item $key

Bezeichner Bild-Sequenz.

=back

=head4 Options

=over 4

=item -count => $n (Default: 0 = keine Beschränkung)

Liefere maximal $n Bilder.

=back

=cut

# -----------------------------------------------------------------------------

sub images {
    my ($self,$key) = @_;

    # Optionen

    my $count = 0;

    Quiq::Option->extract(\@_,
        -count => \$count,
    );

    my @images;

    if ($key =~ s|^(\d{4}-\d{2}-\d{2}-[A-Z])[^/]*/?||s) {
        # Bilder aus Verzeichnis
        @images = $self->directory($1)->images($key);
    }
    else {
        # Bilder gemäß Pool-Sequenz-Datei

        my $file = sprintf '%s/seq/%s.def',$self->root,$key;
        my $fh = Quiq::FileHandle->new('<',$file);
        while (<$fh>) {
            chomp;
            push @images,$self->images($_);
        }
        $fh->close;
    }

    if ($count && $count < @images) {
        $#images = $count-1;
    }

    return wantarray? @images: \@images;
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
