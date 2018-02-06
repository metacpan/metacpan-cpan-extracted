package Prty::Storable;
use base qw/Prty::Object/;

use strict;
use warnings;

our $VERSION = 1.123;

use Storable ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Storable - Persistenz für Perl-Datenstrukturen

=head1 BASE CLASS

L<Prty::Object>

=head1 DESCRIPTION

Die Klasse ist ein objektorientierter Wrapper für das Core-Modul
Storable, speziell für die Funktionen freeze(), thaw(), clone().

=head1 METHODS

=head2 Klassenmethoden

=head3 clone() - Deep Copy einer Datenstruktur

=head4 Synopsis

    $cloneRef = Prty::Storable->clone($ref);

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

    $str = Prty::Storable->freeze($ref);

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

    $ref = Prty::Storable->thaw($str);

=cut

# -----------------------------------------------------------------------------

sub thaw {
    my $class = shift;
    # @_: $str
    return Storable::thaw($_[0]);
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
