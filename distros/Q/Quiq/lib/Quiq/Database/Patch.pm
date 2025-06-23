# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Patch - Definiere Patches für eine Datenbank und wende sie an (Basisklasse)

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Abgeleitete Patch-Klasse mit Patch-Methoden patch1() ...
patchN() definieren:

  package MyPatchClass;
  use base qw/Quiq::Database::Patch/;
  
  sub patch1 {
      my ($self,$db) = @_;
  
      # Code Patch 1
  
      return;
  }
  
  sub patch2 {
      my ($self,$db) = @_;
  
      # Code Patch 2
  
      return;
  }
  
  # ...

Ein oder mehrere Patches auf eine Datenbank anwenden:

  $db = Quiq::Database::Connection->new($udl);
  $pat = MyPatchClass->new($db);
  $pat->apply($n);

=head1 DESCRIPTION

Wir entwickeln eine Datenbank, indem wir fortgesetzt Patches auf
sie anwenden. Die Patches können Schema- oder Datenänderungen
betreffen.  Die Patches werden fortschreitend in einer einzigen
Klasse definiert. Die Patchklasse ist von der Klasse Quiq::Database::Patch
abgeleitet. Jeder Patch wird durch eine Methode mit dem Namen
C<patch>I<N> realisiert.  Hierbei ist I<N> der Patchlevel. Wir
heben die Datenbank auf Patchlevel $n, indem wir die Methode
C<< $pat->apply($n) >> aufrufen.  Alle Patches vom aktuellen
Patchlevel+1 bis $n werden dabei nacheinander auf die Datenbank
angewandt. Ist der aktuelle Patchlevel gleich oder größer dem
angeforderten Patchlevel $n, wird kein Patch angewandt. Auf einen
früheren Patchlevel als den aktuellen Patchlevel kann nicht
zurückgegangen werden. Soll ein Patch zurückgenommen werden, ist
ein weiterer Patch zu schreiben, der diesen rückgängig macht.
Jeder Patch wird einzeln committet. Der aktuelle Patchlevel ist in
der Tabelle C<PATCHLEVEL> festgehalten. Diese wird beim ersten
Aufruf der Methode C<< $class->new($db) >> automatisch angelegt.

=cut

# -----------------------------------------------------------------------------

package Quiq::Database::Patch;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $pat = $class->new($db);

=head4 Arguments

=over 4

=item $db

(Object) Datenbankverbindung

=back

=head4 Returns

Patch-Object

=head4 Description

Instantiiere eine Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$db) = @_;

    # Patchlevel-Tabelle anlegen, falls sie nicht existiert

    if (!$db->tableExists('patchlevel')) {
        $db->createTable('patchlevel',
            ['pat_id',type=>'INTEGER',notNull=>1],
        );
        $db->insert('patchlevel',pat_id=>0);
    }

    # Instantiiere Objekt

    return $class->SUPER::new(
        db => $db,
    );
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 maxLevel() - Liefere den höchsten möglichen Patchlevel

=head4 Synopsis

  $level = this->maxLevel;

=head4 Returns

(Integer) Patchlevel

=head4 Description

Ermittele den höchsten möglichen Patchlevel und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub maxLevel {
    my $this = shift;

    my $level = 0;

    while (1) {
        my $method = sprintf 'patch%d',$level+1;
        if (!$this->can($method)) {
            last;
        }
        $level++;
    }

    return $level;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 apply() - Wende Patch(es) an

=head4 Synopsis

  $pat->apply($level);

=head4 Arguments

=over 4

=item $level

(Integer) Patchlevel

=back

=head4 Description

Wende alle Patches an, bis Patchlevel $level erreicht ist.

=cut

# -----------------------------------------------------------------------------

sub apply {
    my ($self,$level) = @_;

    my $db = $self->db;

    # Aktuellen Patchlevel ermitteln
    my $currLevel = $self->currentLevel;

    # Überprüfe die Existenz der erforderlichen Patch-Methoden

    for (my $i = $currLevel+1; $i <= $level; $i++) {
        my $method = sprintf 'patch%d',$i;
        if (!$self->can($method)) {
            $self->throw(
                'PATCH-00001: Patch method does not exist',
                Patch => $method,
            );
        }
    }

    # Wende Patch-Methoden an

    for (my $i = $currLevel+1; $i <= $level; $i++) {
        my $method = sprintf 'patch%d',$i;
        say "Applying $method()...";
        $db->begin;
        $self->$method($db);
        $db->update('patchlevel',pat_id=>$i);
        $db->commit;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 currentLevel() - Liefere aktuellen Patchlevel

=head4 Synopsis

  $level = $pat->currentLevel;

=head4 Returns

(Integer) Patchlevel

=head4 Description

Ermittele den aktuellen Patchlevel und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub currentLevel {
    return shift->db->value('patchlevel','pat_id');
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
