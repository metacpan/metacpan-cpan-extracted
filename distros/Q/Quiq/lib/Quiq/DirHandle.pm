package Quiq::DirHandle;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::DirHandle - Verzeichnis-Handle

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

    use Quiq::DirHandle;
    
    my $dh = Quiq::DirHandle->new($dir);
    while (my $entry = $dh->next) {
        say $entry;
    }
    $dh->close;

=head1 DESCRIPTION

Die Klasse stellt eine objektorientierte Schnittstelle zu
Perls Directory Handles her. Mit den Methoden der Klasse kann
ein Verzeichnis geöffnet und über seine Einträge iteriert werden.

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new() - Instantiiere Directory-Handle

=head4 Synopsis

    $dh = $class->new($dir);

=head4 Description

Instantiiere ein Dirhandle-Objekt für Verzeichnis $dir und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dir) = @_;

    opendir my $dh,$dir or do {
        $class->throw(
            'DIR-00001: Verzeichnis öffnen fehlgeschlagen',
            Dir => $dir,
            Error => "$!",
        );
    };

    return bless $dh,$class;
}

# -----------------------------------------------------------------------------

=head3 close() - Schließe Verzeichnis

=head4 Synopsis

    $dh->close;

=head4 Description

Schließe das Verzeichnis. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub close {
    my ($self) = @_;

    closedir $self or do {
        $self->throw(
            'DIR-00002: Dirhandle schließen fehlgeschlagen',
            Error => "$!",
        );
    };

    $_[0] = undef;

    return;
}

# -----------------------------------------------------------------------------

=head2 Operationen

=head3 next() - Liefere nächsten Verzeichniseintrag

=head4 Synopsis

    $entry = $dh->next;

=head4 Description

Liefere den nächsten Verzeichniseintrag. Die Einträge werden in
der Reihenfolge geliefert, wie sie im Verzeichnis stehen, also
de facto ungeordnet. Ist das Ende erreicht, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub next {
    return readdir shift;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
