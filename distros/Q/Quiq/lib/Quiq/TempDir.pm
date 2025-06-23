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

=cut

# -----------------------------------------------------------------------------

package Quiq::TempDir;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use overload '""' => sub {${$_[0]}}, 'cmp' => sub{${$_[0]} cmp $_[1]};
use Quiq::Path;
use File::Temp ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $dir = $class->new;

=head4 Options

=over 4

=item -cleanup => $bool (Default: 1)

Entferne das Verzeichnis bei Beendigung des Programms. Wenn 0, bleibt das
Verzeichnis nach Beendigung des Programms bestehen.

=item -parentDir => $dir

Erzeuge das temporäre Verzeichnis unterhalb von Verzeichnis $dir.

=back

=head4 Returns

Tempverzeichnis-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @opt

    # Optionen und Argumente

    my $cleanup = 1;
    my $parentDir = undef;

    my $argA = $class->parameters(0,0,\@_,
        -cleanup => \$cleanup,
        -parentDir => \$parentDir,
    );

    # Wir setzen unsere Optionen in die Optionen von File::Temp::newdir() um

    my @args;
    if (defined $cleanup) {
        push @args,'CLEANUP',$cleanup;
    }
    if ($parentDir) {
        push @args,'DIR',Quiq::Path->expandTilde($parentDir);
    }

    # Objekt instantiieren
    return bless \File::Temp->newdir(@args),$class;
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
