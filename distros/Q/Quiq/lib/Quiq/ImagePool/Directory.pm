package Quiq::ImagePool::Directory;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::TimeLapse::Directory;
use Quiq::Option;
use Quiq::ImagePool::Sequence;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ImagePool::Directory - Unterverzeichnis eines Image-Pool

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Directory-Objekt

=head4 Synopsis

    $dir = $class->new($path);

=head4 Arguments

=over 4

=item path

Verzeichnis-Pfad.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$path) = @_;

    return $class->SUPER::new(
        path => $path,
        imageList => Quiq::TimeLapse::Directory->new("$path/img"),
        sequenceH => {},
    );
}

# -----------------------------------------------------------------------------

=head2 Sequenzen

=head3 sequence() - Lookup Sequence-Objekt nach Name

=head4 Synopsis

    $seq = $dir->sequence($name,@opt);

=head4 Arguments

=over 4

=item $name

Name der Sequenz.

=back

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Liefere undef, wenn die Sequenz-Datei nicht existiert oder
keinen Range definiert.

=back

=head4 Description

Liefere das Sequenz-Objekt mit Name $name. Das Objekt wird
gecached. Existiert das Verzeichnis nicht, wird eine Exception
geworfen, es sei denn, die Option -sloppy ist gesetzt.

=cut

# -----------------------------------------------------------------------------

sub sequence {
    my $self = shift;
    my $name = shift;
    # @_: @opt

    return $self->{'sequenceH'}->{$name} //= do {
        # Optionen

        my $sloppy = 0;

        Quiq::Option->extract(\@_,
            -sloppy=>\$sloppy,
        );

        my $seq;
        my $file = sprintf '%s/seq/%s.def',$self->path,$name;
        if (!-e $file && $sloppy) {
            # nichts tun
        }
        else {
            my $lst = $self->imageList;
            $seq = Quiq::ImagePool::Sequence->new($file,$lst);
            if ($seq->count == 0 && $sloppy) {
                $seq = undef;
            }
        }
        $seq;
    };
}

# -----------------------------------------------------------------------------

=head2 Bilder

=head3 images() - Liste von Bildern aus dem Verzeichnis

=head4 Synopsis

    @images|$imageA = $dir->images($key);

=head4 Description

Liefere die Bild-Teilmenge $key. Der Schlüssel $key kann die
Ausprägungen annehmen:

=over 2

=item *

nicht agegeben oder leer

=item *

Sequenz-Bezeichner SEQUENCE

=item *

Range-Bezeichner SEQUENCE/RANGE

=back

=cut

# -----------------------------------------------------------------------------

sub images {
    my ($self,$key) = @_;

    if (!$key) {
        if (my $seq = $self->sequence('default',-sloppy=>1)) {
            # Wenn eine nicht-leere Default-Sequenz existiert,
            # liefern wir deren Bilder
            return $seq->images;
        }
        # andernfalls liefern wir alle Bilder des Verzeichnisses
        return $self->imageList->images;
    }

    # Liefere die Bilder der Sequenz oder des Range

    my ($sequence,$range) = split m|/|,$key;
    return $self->sequence($sequence)->images($range);
}

# -----------------------------------------------------------------------------

=head3 image() - Lookup Bild-Objekt nach Bild-Nummer

=head4 Synopsis

    $img = $dir->image($n);

=cut

# -----------------------------------------------------------------------------

sub image {
    my ($self,$n) = @_;
    return $self->imageList->image($n);
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
