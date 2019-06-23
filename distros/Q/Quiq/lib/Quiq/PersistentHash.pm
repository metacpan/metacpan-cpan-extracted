package Quiq::PersistentHash;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.147';

use Fcntl ();
use DB_File ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PersistentHash - Persistenter Hash

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    my $h = $class->new($file,$mode,@args);

=head4 Description

Öffne einen Hash mit Datei $file als persistentem Speicher
im Modus $mode und liefere eine Referenz auf diesen Hash zurück.

Die Argumente @args entspechen den Argumenten des Konstruktors
der Basisklasse. Details siehe dort.

B<Modes>

    Mode  Bedeutung
    ----  --------------------------------------------------------------
     r    nur lesen, Datei muss existieren
     w    nur schreiben, Datei wird angelegt, falls nicht existent
     rw   lesen und schreiben, Datei wird angelegt, falls nicht existent

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $file = shift;
    my $mode = shift;
    # @_: Argumente

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

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub sync {
    my $self = shift;

    my $x = tied %$self || $self->throw(
        'BDB-00002: Kann Tie-Objekt nicht ermitteln',
    );
    if ($x->sync < 0) {
        $self->throw(
            'BDB-00003: Sync ist fehlgeschlagen',
            Errstr => $!,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 close() - Schließe Persistenten Hash

=head4 Synopsis

    $h->close;

=cut

# -----------------------------------------------------------------------------

sub close {
    untie %{$_[0]};
    $_[0] = undef;
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
