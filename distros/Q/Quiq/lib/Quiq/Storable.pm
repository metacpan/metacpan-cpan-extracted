package Quiq::Storable;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Storable ();
use Quiq::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Storable - Persistenz für Perl-Datenstrukturen

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Die Klasse ist ein objektorientierter Wrapper für das Core-Modul
Storable, speziell für die Funktionen freeze(), thaw(), clone().

=head1 METHODS

=head2 Klassenmethoden

=head3 clone() - Deep Copy einer Datenstruktur

=head4 Synopsis

    $cloneRef = Quiq::Storable->clone($ref);

=cut

# -----------------------------------------------------------------------------

sub clone {
    my $class = shift;
    # @_: $ref
    return Storable::dclone($_[0]);
}

# -----------------------------------------------------------------------------

=head3 freeze() - Serialisiere Datenstruktur zu Zeichenkette

=head4 Synopsis

    $str = Quiq::Storable->freeze($ref);

=cut

# -----------------------------------------------------------------------------

sub freeze {
    my $class = shift;
    # @_: $ref
    return Storable::freeze($_[0]);
}

# -----------------------------------------------------------------------------

=head3 thaw() - Deserialisiere Zeichenkette zu Datenstruktur

=head4 Synopsis

    $ref = Quiq::Storable->thaw($str);

=cut

# -----------------------------------------------------------------------------

sub thaw {
    my $class = shift;
    # @_: $str
    return Storable::thaw($_[0]);
}

# -----------------------------------------------------------------------------

=head3 memoize() - Cache Datenstruktur in Datei

=head4 Synopsis

    $ref = Quiq::Storable->memoize($file,$sub);

=head4 Description

Existiert Datei $file, deserialisiere die enthaltene Datenstruktur.
Andernfalls erzeuge die Datenstruktur durch Aufruf der Subroutine $sub
und speichere sie in Datei $file. In beiden Fällen liefere eine
Referenz auf die Datenstuktur zurück.

Soll die Datenstuktur erneut generiert werden, genügt es, die Datei
zuvor zu löschen.

=head4 Example

Cache Hash mit zyklischer Struktur:

    my $cacheFile = '~/tmp/test5674';
    my $objectH = Quiq::Storable->memoize($cacheFile,sub {
        my $h;
        $h->{'A'} = [1,undef];
        $h->{'B'} = [2,undef];
        $h->{'A'}[1] = \$h->{'B'};
        $h->{'B'}[1] = \$h->{'A'};
        return $h;
    });

=cut

# -----------------------------------------------------------------------------

sub memoize {
    my ($class,$file,$sub) = @_;

    my $p = Quiq::Path->new;

    my $ref;
    if ($p->exists($file)) {
        $ref = $class->thaw($p->read($file));
    }
    else {
        $ref = $sub->();
        $p->write($file,$class->freeze($ref));
    }

    return $ref;
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
