# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Hash::Db - Persistenter Hash

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse ist eine objektorientierte Überdeckung des Moduls DB_File,
das eine Schnittstelle zu Berkeley DB 1.x darstellt.

=head1 EXAMPLE

Alle Hash-Keys ausgeben ($file ist der Name der Hash-Datei):

  $ perl -MQuiq::Hash::Db -E '$h = Quiq::Hash::Db->new($file,"r"); for (keys %$h) { say $_}'

=cut

# -----------------------------------------------------------------------------

package Quiq::Hash::Db;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Quiq::Path;
use Fcntl ();
use DB_File ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  my $h = $class->new($file,$mode);

=head4 Arguments

=over 4

=item $file

Datei, in dem der Hash gespeichert wird.

=item $mode

Modus, in dem die Datei geöffnet wird:

  Mode  Bedeutung
  ----  --------------------------------------------------------------
   r    nur lesen, Datei muss existieren
   w    nur schreiben, Datei wird angelegt, falls nicht existent
   rw   lesen und schreiben, Datei wird angelegt, falls nicht existent

=back

=head4 Returns

Referenz auf das Hash-Objekt.

=head4 Description

Öffne einen Hash mit Datei $file als persistentem Speicher
im Modus $mode und liefere eine Referenz auf das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file,$mode) = @_;

    $file = Quiq::Path->expandTilde($file);

    my $openMode = 0;
    if ($mode eq 'rw') {
        $openMode = Fcntl::O_RDWR|Fcntl::O_CREAT;
    }
    elsif ($mode eq 'r') {
        $openMode = Fcntl::O_RDONLY;
    }
    elsif ($mode eq 'w') {
        $openMode = Fcntl::O_WRONLY|Fcntl::O_CREAT;
    }
    else {
        $class->throw(
            'BDB-00001: Unbekannter Mode',
            Mode => $mode,
        );
    }

    my %hash;
    my $ref =  tie %hash,'DB_File',$file,$openMode,0644,
        $DB_File::DB_HASH;
    unless ($ref) {
        $class->throw(
            'BDB-00001: Kann Persistenten Hash nicht öffnen',
            File => $file,
            Mode => $mode,
            Errstr => $!,
        );
    }

    return bless \%hash,$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 sync() - Schreibe Cache-Daten auf Platte

=head4 Synopsis

  $h->sync;

=cut

# -----------------------------------------------------------------------------

sub sync {
    my $self = shift;

    my $ref = tied %$self || $self->throw(
        'BDB-00002: Kann Tie-Objekt nicht ermitteln',
    );
    my $r = $ref->sync;
    if ($r < 0) {
        $self->throw(
            'BDB-00003: Sync ist fehlgeschlagen',
            TiedObject => "$ref",
            Errcode => $r,
            Errstr => $!,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 close() - Schließe Persistenten Hash

=head4 Synopsis

  $h->close;

=head4 Description

Schreibe den Persistenten Hash auf Platte und zerstöre das Objekt.
Das gleiche geschieht, wenn die letzte Referenz auf das Objekt aus
dem Scope geht.

=cut

# -----------------------------------------------------------------------------

sub close {
    untie %{$_[0]};
    $_[0] = undef;
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
