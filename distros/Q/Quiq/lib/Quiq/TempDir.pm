package Quiq::TempDir;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use overload '""' => sub {${$_[0]}}, 'cmp' => sub{${$_[0]} cmp $_[1]};
use File::Temp ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TempDir - Temporäres Verzeichnis

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Der Konstruktor der Klasse erzeugt ein temporäres Verzeichnis.
Geht die letzte Objekt-Referenz aus dem Scope, wird das Verzeichnis
automatisch gelöscht. Das Verzeichnis-Objekt stringifiziert sich
im String-Kontext automatisch zum Verzeichnis-Pfad.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $dir = $class->new;

=head4 Returns

Tempverzeichnis-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless \File::Temp->newdir,$class;
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
